# Copyright (C) 2013  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2013-2020  Sutou Kouhei <kou@clear-code.com>
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

require "net/http"

require "groonga/client/version"
require "groonga/client/empty-request"
require "groonga/client/protocol/error"
require "groonga/client/protocol/http/path-resolvable"

module Groonga
  class Client
    module Protocol
      class HTTP
        class Synchronous
          # TODO: Workaround to disable retry in net/http.
          class HTTPClient < Net::HTTP
            class ReadTimeout < StandardError
            end

            module ReadTimeoutConvertable
              def rbuf_fill
                begin
                  super
                rescue Net::ReadTimeout => error
                  raise ReadTimeout, error.message, error.backtrace
                end
              end
            end

            private
            def on_connect
              @socket.extend(ReadTimeoutConvertable)
            end
          end

          include PathResolvable

          def initialize(url, options={})
            @url = url
            @options = options
          end

          def send(command)
            begin
              HTTPClient.start(@url.host, @url.port, start_options) do |http|
                http.read_timeout = read_timeout
                response = send_request(http, command)
                case response
                when Net::HTTPSuccess, Net::HTTPBadRequest
                  yield(response.body)
                else
                  if response.body.start_with?("[[")
                    yield(response.body)
                  else
                    message =
                      "#{response.code} #{response.message}: #{response.body}"
                    raise Error.new(message)
                  end
                end
              end
            rescue SystemCallError, Timeout::Error
              raise WrappedError.new($!)
            end
            EmptyRequest.new
          end

          # @return [false] Always returns false because the current
          #   implementation doesn't support keep-alive.
          def connected?
            false
          end

          # Does nothing because the current implementation doesn't
          # support keep-alive. If the implementation supports
          # keep-alive, it close the opend connection.
          #
          # @overload close
          #   Closes synchronously.
          #
          #   @return [false] It always returns false because there is always
          #      no connection.
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
            if sync
              false
            else
              yield
              EmptyRequest.new
            end
          end

          private
          def start_options
            tls_options = @options[:tls] || {}
            case tls_options[:verify_mode]
            when :none
              tls_options[:verify_mode] = OpenSSL::SSL::VERIFY_NONE
            when :peer
              tls_options[:verify_mode] = OpenSSL::SSL::VERIFY_PEER
            end

            {
              :use_ssl => @url.scheme == "https",
              :ca_file => tls_options[:ca_file],
              :ca_path => tls_options[:ca_path],
              :verify_mode => tls_options[:verify_mode],
            }
          end

          def read_timeout
            timeout = @options[:read_timeout]
            if timeout.nil? or timeout < 0
              nil
            else
              timeout
            end
          end

          def send_request(http, command)
            if command.is_a?(Groonga::Command::Load)
              request = prepare_load_request(command)
            else
              path = resolve_path(@url, command.to_uri_format)
              request = Net::HTTP::Get.new(path, headers)
            end
            setup_authentication(request)
            http.request(request)
          end

          def headers
            {
              "user-agent" => @options[:user_agent],
            }
          end

          def prepare_load_request(command)
            path_prefix = command.path_prefix
            command = command.class.new(command.command_name,
                                        command.arguments,
                                        [])
            command.path_prefix = path_prefix
            case @options[:load_input_type]
            when "apache-arrow"
              command[:input_type] = "apache-arrow"
              content_type = "application/x-apache-arrow-streaming"
              arrow_table = command.build_arrow_table
              if arrow_table
                buffer = Arrow::ResizableBuffer.new(1024)
                arrow_table.save(buffer, format: :stream)
                body = buffer.data.to_s
              else
                body = ""
              end
              command.arguments.delete(:values)
            else
              content_type = "application/json"
              body = command.arguments.delete(:values)
            end
            path = resolve_path(@url, command.to_uri_format)
            request = Net::HTTP::Post.new(path, headers)
            if @options[:chunk]
              request["Transfer-Encoding"] = "chunked"
            else
              request.content_length = body.bytesize
            end
            request.content_type = content_type
            request.body_stream = StringIO.new(body)
            request
          end

          def setup_authentication(request)
            userinfo = @url.userinfo
            return if userinfo.nil?

            user, password = userinfo.split(/:/, 2).collect do |component|
              URI.decode_www_form_component(component)
            end
            request.basic_auth(user, password)
          end
        end
      end
    end
  end
end
