# Copyright (C) 2016  Masafumi Yokoyama <yokoyama@clear-code.com>
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

class TestResponseTableRemove < Test::Unit::TestCase
  class TestParseRawResponse < self
    include TestResponseHelper

    def test_table_remove
      header = [0,1372430096.70991,0.000522851943969727]
      body = true
      raw_response = [header, body].to_json

      response = parse_raw_response("table_remove", raw_response)
      assert_equal(Groonga::Client::Response::TableRemove, response.class)
    end
  end
end
