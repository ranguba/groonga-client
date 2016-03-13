# Copyright (C) 2013-2016  Kouhei Sutou <kou@clear-code.com>
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

require "groonga/client/protocol/http"

class TestProtocolHTTP < Test::Unit::TestCase
  def setup
    setup_server
    setup_client
  end

  def teardown
    teardown_client
    teardown_server
  end

  def setup_server
    @address = "127.0.0.1"
    @server = TCPServer.new(@address, 0)
    @port = @server.addr[1]

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

  def setup_client
    @client = nil
  end

  def teardown_client
    @client.close if @client
  end

  def connect(options={})
    url = URI::HTTP.build(:host => @address,
                          :port => @port)
    Groonga::Client::Protocol::HTTP.new(url, options)
  end

  def test_connected?
    @client = connect
    assert_false(@client.connected?)
  end

  class TestClose < self
    def test_twice
      @client = connect
      assert_false(@client.close)
      assert_false(@client.close)
    end
  end
end
