# Copyright (C) 2014  Kouhei Sutou <kou@clear-code.com>
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

require "coolio"

require "groonga/client/empty-request"
require "groonga/client/protocol/error"

module Groonga
  class Client
    module Protocol
      class HTTP
        class Coolio
          class Request
            def initialize(client, loop)
              @client = client
              @loop = loop
            end

            def wait
              until @client.finished?
                @loop.run_once
              end
            end
          end

          class GroongaHTTPClient < ::Coolio::HttpClient
            def initialize(socket, callback)
              super(socket)
              @body = ""
              @callback = callback
              @finished = false
            end

            def finished?
              @finished
            end

            def on_body_data(data)
              @body << data
            end

            def on_request_complete
              @callback.call(@body)
            end

            def on_close
              super
              @finished = true
            end
          end

          def initialize(host, port, options)
            @host = host
            @port = port
            @options = options
            @loop = @options[:loop] || ::Coolio::Loop.default
          end

          def send(command, &block)
            client = GroongaHTTPClient.connect(@host, @port, block)
            client.attach(@loop)
            client.request("GET", command.to_uri_format)
            Request.new(client, @loop)
          end

          def connected?
            false
          end

          def close(&block)
            sync = !block_given?
            if sync
              false
            else
              yield
              EmptyRequest.new
            end
          end
        end
      end
    end
  end
end
