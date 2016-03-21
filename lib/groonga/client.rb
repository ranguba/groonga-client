# Copyright (C) 2013  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2013-2016  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require "uri"
require "json"

require "groonga/client/default"
require "groonga/client/command"
require "groonga/client/empty-request"
require "groonga/client/protocol/gqtp"
require "groonga/client/protocol/http"
require "groonga/client/script-syntax"

module Groonga
  class Client
    class << self
      @@deafult_options = {}

      # @return [Hash] The default options for {Groonga::Client.new}.
      #
      # @since 0.2.0
      def default_options
        @@deafult_options
      end

      # @param [Hash] options The new default options for
      #   {Groonga::Client.new}.
      #
      # @since 0.2.0
      def default_options=(options)
        @@deafult_options = options
      end

      # @!macro [new] initialize_options
      #   @param [Hash] options The options.
      #   @option options [String, URI::Generic, URI::HTTP, URI::HTTPS]
      #     :url The URL of Groonga server.
      #   @option options [:gqtp, :http, :https] :protocol The
      #     protocol that is used by the client.
      #   @option options [String] :user User ID. Currently used for HTTP
      #     Basic Authentication.
      #   @option options [String] :password Password. Currently used for
      #     HTTP Basic Authentication.
      #
      # @overload open(options={})
      #   Opens a new client connection.
      #
      #   @macro initialize_options
      #   @return [Client] The opened client.
      #
      # @overload open(options={}) {|client| }
      #   Opens a new client connection while the block is evaluated.
      #   The block is finished the opened client is closed.
      #
      #   @macro initialize_options
      #   @yield [client] Gives a opened client to the block. The opened
      #     client is closed automatically when the block is finished.
      #   @yieldparam client [Client] The opened client.
      #   @yieldreturn [Object] Any object.
      #   @return [Object] Any object that is returned by the block.
      def open(options={}, &block)
        client = new(options)
        if block_given?
          begin
            yield(client)
          ensure
            client.close
          end
        else
          client
        end
      end
    end

    # @macro initialize_options
    def initialize(options={})
      options = self.class.default_options.merge(options)
      url = options[:url] || build_url(options)
      url = URL.parse(url) unless url.is_a?(URI::Generic)
      options[:url] = url
      options[:read_timeout] ||= Default::READ_TIMEOUT

      @connection = nil
      case url.scheme
      when "gqtp"
        @connection = Groonga::Client::Protocol::GQTP.new(url, options)
      when "http", "https"
        @connection = Groonga::Client::Protocol::HTTP.new(url, options)
      else
        message = "unsupported scheme: <#{url.scheme}>: "
        message << "supported: [gqtp, http, https]"
        raise ArgumentError, message
      end
    end

    # Closes the opened client connection if the current connection is
    # still opened. You can't send a new command after you call this
    # method.
    #
    # @overload close
    #   Closes synchronously.
    #
    #   @return [Boolean] true when the opened connection is closed.
    #      false when there is no connection.
    #
    # @overload close {}
    #   Closes asynchronously.
    #
    #   @yield [] Calls the block when the opened connection is closed.
    #   @return [#wait] The request object. If you want to wait until
    #      the request is processed. You can send #wait message to the
    #      request.
    def close(&block)
      sync = !block_given?
      if @connection
        close_request = @connection.close do
          yield unless sync
          @connection = nil
        end
        if sync
          close_request.wait
          true
        else
          close_request
        end
      else
        if sync
          false
        else
          EmptyRequest.new
        end
      end
    end

    def load(parameters, &block)
      values = parameters[:values]
      if values.is_a?(Array)
        json = "["
        values.each_with_index do |value, i|
          if i.zero?
            json << "\n"
          else
            json << ",\n"
          end
          json << JSON.generate(value)
        end
        json << "\n]"
        parameters[:values] = json
      end
      execute(:load, parameters, &block)
    end

    def execute(command_or_name, parameters={}, &block)
      if command_or_name.is_a?(Command)
        command = command_or_name
      else
        command_name = command_or_name
        parameters = normalize_parameters(parameters)
        command_class = Groonga::Command.find(command_name)
        command = command_class.new(command_name, parameters)
      end
      execute_command(command, &block)
    end

    def method_missing(name, *args, **kwargs, &block)
      if groonga_command_name?(name)
        execute(name, *args, **kwargs, &block)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private)
      if groonga_command_name?(name)
        true
      else
        super
      end
    end

    private
    def build_url(options)
      scheme = (options.delete(:protocol) || "gqtp").to_s
      host = options.delete(:host) || options.delete(:address) || "127.0.0.1"
      port = options.delete(:port) || default_port(scheme)
      user = options.delete(:user)
      password = options.delete(:password)
      if user and password
        userinfo = "#{user}:#{password}"
      else
        userinfo = nil
      end

      arguments = [
        scheme,
        userinfo,
        host,
        port,
        nil,
        nil,
        nil,
        nil,
        nil,
      ]
      case scheme
      when "http"
        URI::HTTP.new(*arguments)
      when "https"
        URI::HTTPS.new(*arguments)
      else
        URI::Generic.new(*arguments)
      end
    end

    def default_port(scheme)
      case scheme
      when "gqtp"
        10043
      when "http", "https"
        10041
      else
        nil
      end
    end

    def groonga_command_name?(name)
      /\A[a-zA-Z][a-zA-Z\d_]+\z/ === name.to_s
    end

    def normalize_parameters(parameters)
      normalized_parameters = {}
      parameters.each do |key, value|
        normalized_parameters[key] = value.to_s
      end
      normalized_parameters
    end

    def execute_command(command, &block)
      Client::Command.new(command).execute(@connection, &block)
    end
  end
end
