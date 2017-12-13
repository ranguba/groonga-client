# Copyright (C) 2017  Kouhei Sutou <kou@clear-code.com>
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

require "groonga/client/version"
require "groonga/client/protocol/error"

module Groonga
  class Client
    module Protocol
      class File
        def initialize(url, options)
          @url = url
          @options = options
        end

        def send(command, &block)
          open_pipes do |input, output, error|
            options = {
              :in => input[0],
              :out => output[1],
              :err => error[1],
            }
            pid = spawn("groonga", @url.path, options)
            input[0].close
            output[1].close
            error[1].close

            input[1].puts(command.to_command_format)
            input[1].close
            response = output[0].read
            Process.waitpid(pid)
            yield(response)
            EmptyRequest.new
          end
        end

        def connected?
          false
        end

        def close(&block)
          if block_given?
            yield
            EmptyRequest.new
          else
            false
          end
        end

        private
        def open_pipes
          IO.pipe do |input|
            IO.pipe do |output|
              IO.pipe do |error|
                yield(input, output, error)
              end
            end
          end
        end
      end
    end
  end
end
