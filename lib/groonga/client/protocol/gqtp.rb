# -*- coding: utf-8 -*-
#
# Copyright (C) 2013  Haruka Yoshihara <yoshihara@clear-code.com>
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

require "gqtp"

module Groonga
  class Client
    module Protocol
      class GQTP
        def initialize(options)
          @client = ::GQTP::Client.new(options)
        end

        def send(command, &block)
          formatted_command = command.to_command_format
          response = nil

          request = @client.send(formatted_command) do |header, body|
            if block_given?
              response = yield(body)
            else
              response = body
            end
          end
          request.wait
          response
        end
      end
    end
  end
end
