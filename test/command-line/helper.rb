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

require "groonga/command/parser"

require "groonga/client"
require "groonga/client/test-helper"

module CommandLineTestHelper
  def groonga_url
    @groonga_server_runner.url.to_s
  end

  def open_client
    Groonga::Client.open(:url => groonga_url) do |client|
      yield(client)
    end
  end

  def restore(commands)
    open_client do |client|
      values = nil
      Groonga::Command::Parser.parse(commands) do |event, *args|
        case event
        when :on_command
          command, = args
          response = client.execute(command)
          unless response.success?
            raise Groonga::Client::Request::ErrorResponse.new(response)
          end
        when :on_load_start
          command, = args
          values = []
        when :on_load_columns
          command, columns = args
          command[:columns] ||= columns.join(",")
        when :on_load_value
          command, value = args
          values << value
        when :on_load_complete
          command, = args
          command[:values] ||= JSON.generate(values)
          response = client.execute(command)
          unless response.success?
            raise Groonga::Client::Request::ErrorResponse.new(response)
          end
        else
          p [:unhandled_event, event, *args]
        end
      end
    end
  end

  def dump
    open_client do |client|
      client.dump.body
    end
  end

  def capture_outputs
    begin
      stdout, $stdout = $stdout, StringIO.new
      stderr, $stderr = $stderr, StringIO.new
      result = yield
      [
        result,
        $stdout.string,
        $stderr.string,
      ]
    ensure
      $stdout, $stderr = stdout, stderr
    end
  end
end
