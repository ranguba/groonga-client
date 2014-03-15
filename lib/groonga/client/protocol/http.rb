# -*- coding: utf-8 -*-
#
# Copyright (C) 2013  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2013  Kouhei Sutou <kou@clear-code.com>
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

require "open-uri"

require "groonga/client/empty-request"
require "groonga/client/protocol/request"
require "groonga/client/protocol/error"

module Groonga
  class Client
    module Protocol
      class HTTP
        def initialize(options)
          @host = options[:host] || "127.0.0.1"
          @port = options[:port] || 10041
        end

        def send(command)
          url = "http://#{@host}:#{@port}#{command.to_uri_format}"
          thread = Thread.new do
            begin
              open(url) do |response|
                body = response.read
                yield(body)
              end
            rescue OpenURI::HTTPError, Timeout::Error
              raise Error.new($!)
            end
          end
          ThreadRequest.new(thread)
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
        #      no connectin.
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
            EmptyRequest.new
          end
        end
      end
    end
  end
end
