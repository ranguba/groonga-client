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

require "gqtp"
require "json"

module Groonga
  class Client
    module Protocol
      class GQTP
        def initialize(options)
          @client = ::GQTP::Client.new(options)
        end

        def send(command)
          formatted_command = command.to_command_format
          raw_response = RawResponse.new(command)
          @client.send(formatted_command) do |header, body|
            raw_response.header = header
            raw_response.body = body
            response = raw_response.to_groonga_command_compatible_response
            yield(response)
          end
        end

        class RawResponse
          attr_accessor :header
          attr_accessor :body
          def initialize(command)
            @start_time = Time.now.to_f
            @command = command
            @header = nil
            @body = nil
          end

          def to_groonga_command_compatible_response
            case @command.output_type
            when :none
              return @body
            else :json
            elapsed_time = Time.now.to_f - @start_time
            output_header = [
              @header.status,
              @start_time,
              elapsed_time,
            ]
            if json?(@body)
              output_body = [JSON.parse(@body)]
            else
              output_body = JSON.parse("[#{@body.chomp}]")
            end
            output = output_body.unshift(output_header)
            JSON.generate(output)
            end
          end

          private
          def json?(body)
            (body.start_with?("[") and body.end_with?("]")) or
              (body.start_with?("{") and body.end_with?("}"))
          end
        end
      end
    end
  end
end
