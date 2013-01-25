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
require "json"

module Groonga
  class Client
    module Protocol
      class GQTP
        def initialize(options)
          @client = ::GQTP::Client.new(options)
          @start_time = nil
        end

        def send(command, &block)
          response = nil
          @start_time = Time.now.to_f
          formatted_command = command.to_command_format
          request = @client.send(formatted_command) do |header, body|
            output = convert_groonga_output(command, header, body)
            if block_given?
              response = yield(output)
            else
              response = output
            end
          end
          request.wait
          response
        end

        private
        def convert_groonga_output(command, header, body)
          return body if command.name == "dump"

          elapsed_time = Time.now.to_f
          output_header = [
            header.status,
            @start_time,
            elapsed_time - @start_time
          ]
          if /\A[^\[{].+[^\]}]/ =~ body
            output_body = JSON.parse("[#{body.chomp}]")
          else
            output_body = [JSON.parse(body)]
          end
          output = output_body.unshift(output_header)
          JSON.generate(output)
        end
      end
    end
  end
end
