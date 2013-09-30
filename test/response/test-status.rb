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

require "response/helper"

class TestResponseStatus < Test::Unit::TestCase
  class TestParseRawResponse < self
    include TestResponseHelper

    def test_class
      header = [0, 1372430096.70991, 0.000522851943969727]
      body = {
        "alloc_count"             => 155,
        "starttime"               => 1380525914,
        "uptime"                  => 54,
        "version"                 => "3.0.8",
        "n_queries"               => 0,
        "cache_hit_rate"          => 0.0,
        "command_version"         => 1,
        "default_command_version" => 1,
        "max_command_version"     => 2,
      }
      raw_response = [header, body].to_json

      response = parse_raw_response("status", raw_response)
      assert_equal(Groonga::Client::Response::Status, response.class)
    end
  end

  class TestBody < self
    def setup
      @command = Groonga::Command::Status.new("status", {})
    end

    private
    def create_response(body)
      header = [0, 1372430096.70991, 0.000522851943969727]
      Groonga::Client::Response::Status.new(@command, header, body)
    end

    class TestReader < self
      def test_alloc_count
        response = create_response({"alloc_count" => 29})
        assert_equal(29, response.alloc_count)
      end

      def test_n_allocations
        response = create_response({"alloc_count" => 29})
        assert_equal(29, response.n_allocations)
      end
    end
  end
end
