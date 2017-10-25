# Copyright (C) 2013  Kosuke Asami
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

require "response/helper"

class TestResponseColumnList < Test::Unit::TestCase
  include TestResponseHelper

  def column(attributes)
    c = Groonga::Client::Response::ColumnList::Column.new
    attributes.each do |name, value|
      c[name] = value
    end
    c
  end

  def test_parse
    header = [0, 1372430096.70991, 0.000522851943969727]
    body = [
      [
        ["id", "UInt32"],
        ["name", "ShortText"],
        ["path", "ShortText"],
        ["type", "ShortText"],
        ["flags", "ShortText"],
        ["domain", "ShortText"],
        ["range", "ShortText"],
        ["source", "ShortText"],
      ],
      [
        256,
        "Text",
        "/tmp/test.db.0000100",
        "var",
        "COLUMN_SCALAR|PERSISTENT",
        "TestTable",
        "ShortText",
        [],
      ],
    ]
    raw_response = [header, body].to_json

    response = parse_raw_response("column_list", raw_response)
    assert_equal([
                   column(:id => 256,
                          :name => "Text",
                          :path => "/tmp/test.db.0000100",
                          :type => "var",
                          :flags => "COLUMN_SCALAR|PERSISTENT",
                          :domain => "TestTable",
                          :range => "ShortText",
                          :source => []),
                 ],
                 response.to_a)
  end
end

