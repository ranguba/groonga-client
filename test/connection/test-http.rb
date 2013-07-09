# -*- coding: utf-8 -*-
#
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

require "groonga/client/connection/http"

class TestConnectionHTTP < Test::Unit::TestCase
  def setup
    setup_server
    setup_connection
  end

  def teardown
    teardown_connection
    teardown_server
  end

  def setup_server
    @address = "127.0.0.1"
    @server = TCPServer.new(@address, 0)
    @port = @server.addr[1]
    @protocol = :http

    @response_body = nil
    @thread = Thread.new do
      client = @server.accept
      @server.close

      status = 0
      start = Time.now.to_f
      elapsed = rand
      header = "[#{status},#{start},#{elapsed}]"
      body = "[#{header},#{@response_body}]"

      http_header = <<-EOH
HTTP/1.1 200 OK
Connection: close
Content-Type: application/json
Content-Length: #{body.bytesize}

EOH

      client.write(http_header)
      client.write(body)
      client.close
    end
  end

  def teardown_server
    @thread.kill
  end

  def setup_connection
    @connection = nil
  end

  def teardown_connection
    @connection.close {} if @connection
  end

  def connect(options={})
    default_options = {
      :host => @address,
      :port => @port,
    }
    Groonga::Client::Connection::HTTP.new(default_options.merge(options))
  end

  def test_connected?
    @connection = connect
    assert_false(@connection.connected?)
  end

  class TestClose < self
    def test_twice
      @connection = connect
      assert_false(@connection.close {})
      assert_false(@connection.close {})
    end
  end
end
