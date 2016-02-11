# -*- coding: utf-8 -*-
#
# Copyright (C) 2013  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2013-2015  Kouhei Sutou <kou@clear-code.com>
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
      # @!macro [new] initialize_options
      #   @param [Hash] options The options.
      #   @option options [:gqtp or :http] :protocol The protocol that is
      #     used by the client.
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
      options = options.dup
      protocol = options.delete(:protocol) || :gqtp
      options[:read_timeout] ||= Default::READ_TIMEOUT

      @connection = nil
      if protocol == :gqtp
        @connection = Groonga::Client::Protocol::GQTP.new(options)
      else
        @connection = Groonga::Client::Protocol::HTTP.new(options)
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

    def cache_limit(parameters, &block)
      execute_command("cache_limit", parameters, &block)
    end

    def check(parameters, &block)
      execute_command("check", parameters, &block)
    end

    def clearlock(parameters={}, &block)
      execute_command("clearlock", parameters, &block)
    end

    def column_create(parameters, &block)
      execute_command("column_create", parameters, &block)
    end

    def column_list(parameters, &block)
      execute_command("column_list", parameters, &block)
    end

    def column_remove(parameters, &block)
      execute_command("column_remove", parameters, &block)
    end

    def column_rename(parameters, &block)
      execute_command("column_rename", parameters, &block)
    end

    def defrag(parameters={}, &block)
      execute_command("defrag", parameters, &block)
    end

    def delete(parameters, &block)
      execute_command("delete", parameters, &block)
    end

    def dump(parameters={}, &block)
      execute_command("dump", parameters, &block)
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
      execute_command("load", parameters, &block)
    end

    def log_level(parameters, &block)
      execute_command("log_level", parameters, &block)
    end

    def log_put(parameters, &block)
      execute_command("log_put", parameters, &block)
    end

    def log_reopen(parameters={}, &block)
      execute_command("log_reopen", parameters, &block)
    end

    def quit(parameters={}, &block)
      execute_command("quit", parameters, &block)
    end

    def register(parameters, &block)
      execute_command("register", parameters, &block)
    end

    def select(parameters, &block)
      execute_command("select", parameters, &block)
    end

    def shutdown(parameters={}, &block)
    end

    def status(parameters={}, &block)
      execute_command("status", parameters, &block)
    end

    def table_create(parameters, &block)
      execute_command("table_create", parameters, &block)
    end

    def table_list(parameters={}, &block)
      execute_command("table_list", parameters, &block)
    end

    def table_remove(parameters, &block)
      execute_command("table_remove", parameters, &block)
    end

    def table_rename(parameters, &block)
    end

    def truncate(parameters, &block)
    end

    def execute(command, &block)
      Client::Command.new(command).execute(@connection, &block)
    end

    private
    def execute_command(command_name, parameters={}, &block)
      parameters = normalize_parameters(parameters)
      command_class = Groonga::Command.find(command_name)
      command = command_class.new(command_name, parameters)
      execute(command, &block)
    end

    def normalize_parameters(parameters)
      normalized_parameters = {}
      parameters.each do |key, value|
        normalized_parameters[key] = value.to_s
      end
      normalized_parameters
    end
  end
end
