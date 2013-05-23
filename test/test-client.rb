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

require "socket"
require "groonga/client"

class TestClient < Test::Unit::TestCase
  module ClientFixture
    class << self
      def included(base)
        super
        base.class_eval do
          setup :setup_client
          teardown :teardown_client
        end
      end
    end

    def setup_client
      @client = nil
    end

    def teardown_client
      @client.close if @client
    end
  end

  module Utils
    def client
      @client ||= open_client
    end

    def open_client(&block)
      options = {:host => @address, :port => @port, :protocol => @protocol}
      Groonga::Client.open(options, &block)
    end

    def groonga_response_header
      [0, "START_TIME", "ELAPSED_TIME"]
    end

    def stub_response(header, body)
      @response_header = header
      @response_body = body
    end
  end

  module Assertions
    def assert_header(response)
      normalized_header = normalize_header(response.header)
      assert_equal(groonga_response_header, normalized_header)
    end

    def assert_response(expected_body, response)
      normalized_header = normalize_header(response.header)
      actual_body = response.body
      actual_body = yield(actual_body) if block_given?
      assert_equal({
                     :header => groonga_response_header,
                     :body   => expected_body,
                   },
                   {
                     :header => normalized_header,
                     :body   => actual_body,
                   })
    end
  end

  module OutputTypeTests
    def test_dump
      dumped_commands = "table_create TEST_TABLE TABLE_NO_KEY"
      stub_response(nil, dumped_commands)
      response = client.dump
      assert_equal([nil, dumped_commands],
                   [response.header, response.body])
    end
  end

  module ColumnsTests
    def test_not_exist
      stub_response(groonga_response_header, '{"key":"value"}')
      response = client.status
      assert_response({"key" => "value"}, response)
    end

    def test_exist
      stub_response(groonga_response_header, <<-JSON)
[[["name","ShortText"],
["age","UInt32"]],
["Alice",32],
["Bob",21]]
JSON
      expected_table_infos = [
        {:name => "Alice", :age => 32},
        {:name => "Bob", :age => 21}
      ]
      response = client.table_list
      assert_response(expected_table_infos, response) do |actual_body|
        actual_body.collect do |value|
          value.table_info
        end
      end
    end
  end

  module ParametersTests
    def test_integer
      stub_response(groonga_response_header, "100")
      response = client.cache_limit(:max => 4)
      assert_response(100, response)
    end
  end

  module Tests
    include Utils
    include Assertions

    include OutputTypeTests
    include ColumnsTests
    include ParametersTests
  end

  class TestGQTP < self
    include Tests
    include ClientFixture

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

    def normalize_header(header)
      start_time = header[1]
      elapsed_time = header[2]
      normalized_header = header.dup
      normalized_header[1] = "START_TIME" if /\A[\d\.]+\z/ =~ start_time.to_s
      normalized_header[2] = "ELAPSED_TIME" if /\A[\d\.]+\z/ =~ elapsed_time.to_s
      normalized_header
    end
  end

  class TestHTTP < self
    include Tests
    include ClientFixture

    def setup
      @address = "127.0.0.1"
      @server = TCPServer.new(@address, 0)
      @port = @server.addr[1]
      @protocol = :http

      @response_body = nil
      @thread = Thread.new do
        client = @server.accept
        @server.close
        if @response_header.nil?
          body = @response_body
        else
          body = "[#{@response_header},\n#{@response_body}]"
        end
        header = <<-EOH
HTTP/1.1 200 OK
Connection: close
Content-Type: application/json
Content-Length: #{body.bytesize}

EOH
        client.write(header)
        client.write(body)
        client.close
      end
    end

    def normalize_header(header)
      header
    end
  end
end
