# Copyright (C) 2014  Kouhei Sutou <kou@clear-code.com>
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

class TestResponseError < Test::Unit::TestCase
  class TestParse < self
    include TestResponseHelper

    def test_class
      header = [
        -22,
        1396012478.14975,
        0.00050806999206543,
        "invalid table name: <Nonexistent>",
        [
          ["grn_select", "proc.c", 897],
        ],
      ]
      raw_response = [header].to_json

      response = parse_raw_response("select", raw_response)
      assert_equal(Groonga::Client::Response::Error, response.class)
    end
  end

  class TestMessage < self
    def test_have_header
      header = [
        -22,
        1396012478.14975,
        0.00050806999206543,
        "invalid table name: <Nonexistent>",
        [
          ["grn_select", "proc.c", 897],
        ],
      ]
      response = Groonga::Client::Response::Error.new(nil, header, nil)
      assert_equal("invalid table name: <Nonexistent>",
                   response.message)
    end

    def test_no_header
      response = Groonga::Client::Response::Error.new(nil, nil, nil)
      assert_equal("", response.message)
    end
  end
end
