# -*- coding: utf-8 -*-
#
# Copyright (C) 2013-2014  Kouhei Sutou <kou@clear-code.com>
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

require "groonga/client/connection/gqtp"

class TestConnectionGQTP < Test::Unit::TestCase
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
    @protocol = :gqtp

    @thread = Thread.new do
      client = @server.accept
      @server.close

      process_client_close(client)

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

  private
  def connect(options={})
    default_options = {
      :host => @address,
      :port => @port,
    }
    Groonga::Client::Connection::GQTP.new(default_options.merge(options))
  end

  def process_client_close(client)
    response_body = [].to_json
    header = GQTP::Header.parse(client.read(GQTP::Header.size))
    client.read(header.size)

    response_header = GQTP::Header.new
    response_header.size = response_body.bytesize

    client.write(response_header.pack)
    client.write(response_body)
  end

  class TestConnect < self
    def test_no_server
      server = TCPServer.new("127.0.0.1", 0)
      free_port = server.addr[1]
      server.close
      assert_raise(Groonga::Client::Connection::Error) do
        Groonga::Client::Connection::GQTP.new(:host => "127.0.0.1",
                                              :port => free_port)
      end
    end
  end

  class TestConnected < self
    def test_opened
      @connection = connect
      assert_true(@connection.connected?)
    end

    def test_closed
      @connection = connect
      @connection.close
      assert_false(@connection.connected?)
    end
  end

  class TestClose < self
    def test_twice
      @connection = connect
      @connection.close
      assert_false(@connection.close)
    end
  end
end
