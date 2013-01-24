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

require "socket"
require "groonga/client"

class TestClient < Test::Unit::TestCase
  module ClientTests
    def test_without_columns_in_responses
      options = {:host => @address, :port => @port, :protocol => @protocol}
      @response_body = <<-JSON
[
[0,1,2],
{"key":"value"}
]
JSON
      expected_header = [0,1,2]
      expected_body = {"key" => "value"}

      Groonga::Client.open(options) do |client|
        response = client.status
        assert_equal(expected_header, response.header)
        assert_equal(expected_body, response.body)
      end
    end

    def test_with_columns_in_responses
      options = {:host => @address, :port => @port, :protocol => @protocol}
      @response_body = <<-JSON
[[0,1,2],
[[["name","ShortText"],
["age","UInt32"]],
["Alice",32],
["Bob",21]]
]
JSON
      expected_header = [0, 1, 2]
      expected_table_infos = [
        {:name => "Alice", :age => 32},
        {:name => "Bob", :age => 21}
      ]

      Groonga::Client.open(options) do |client|
        response = client.table_list
        actual_table_infos = response.body.collect do |value|
          value.table_info
        end
        assert_equal(expected_header, response.header)
        assert_equal(expected_table_infos, actual_table_infos)
      end
    end
  end

  class TestGQTP < self
    def setup
      @address = "127.0.0.1"
      @server = TCPServer.new(@address, 0)
      @port = @server.addr[1]
      @protocol = :gqtp

      @response_body = nil
      @thread = Thread.new do
        client = @server.accept
        @server.close

        header = GQTP::Header.parse(client.read(GQTP::Header.size))
        client.read(header.size)

        response_header = GQTP::Header.new
        response_header.size = @response_body.bytesize

        client.write(response_header.pack)
        client.write(@response_body)
        client.close
      end
    end

    def teardown
      @thread.kill
    end

    include ClientTests
  end

  class TestHTTP < self
    def setup
      @address = "127.0.0.1"
      @server = TCPServer.new(@address, 0)
      @port = @server.addr[1]
      @protocol = :http

      @response_body = nil
      @thread = Thread.new do
        client = @server.accept
        @server.close
        response_header = <<-EOH
HTTP/1.1 200 OK
Connection: close
Content-Type: application/json
Content-Length: #{@response_body.bytesize}

EOH
        client.write(response_header)
        client.write(@response_body)
        client.close
      end
    end

    include ClientTests
  end
end
