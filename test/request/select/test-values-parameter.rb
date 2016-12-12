# Copyright (C) 2016  Kouhei Sutou <kou@clear-code.com>
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

class TestRequestSelectValuesParmater < Test::Unit::TestCase
  def values_parameter(values)
    names = [:match_columns]
    Groonga::Client::Request::ValuesParameter.new(names, values)
  end

  def test_nil
    assert_equal({},
                 values_parameter(nil).to_parameters)
  end

  def test_string
    assert_equal({
                   :match_columns => "title",
                 },
                 values_parameter("title").to_parameters)
  end

  def test_empty_string
    assert_equal({},
                 values_parameter("").to_parameters)
  end

  def test_symbol
    assert_equal({
                   :match_columns => "title",
                 },
                 values_parameter(:title).to_parameters)
  end

  def test_array
    assert_equal({
                   :match_columns => "title, body",
                 },
                 values_parameter(["title", "body"]).to_parameters)
  end

  def test_empty_array
    assert_equal({},
                 values_parameter([]).to_parameters)
  end
end
