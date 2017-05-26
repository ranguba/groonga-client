# Copyright (C) 2016-2017  Yasuhiro Horimoto <horimoto@clear-code.com>
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

class TestRequestSelectScorer < Test::Unit::TestCase
  setup do
    @request = Groonga::Client::Request::Select.new("posts")
  end

  def scorer(expression, values=nil)
    @request.scorer(expression, values).to_parameters
  end

  sub_test_case("expression") do
    def test_nil
      assert_equal({
                     :table => "posts",
                   },
                   scorer(nil))
    end

    def test_string
      assert_equal({
                     :table => "posts",
                     :scorer => "_score = age",
                   },
                   scorer("_score = age"))
    end

    def test_empty_string
      assert_equal({
                     :table => "posts",
                   },
                   scorer(""))
    end

    def test_symbol
      assert_equal({
                     :table => "posts",
                     :scorer => "_score = age",
                   },
                   scorer(:age))
    end
  end

  sub_test_case("values") do
    test("Symbol") do
      assert_equal({
                     :table => "posts",
                     :scorer => "_score = age",
                   },
                   scorer("_score = %{column}", :column => :age))
    end

    test("Symbols") do
      assert_equal({
                     :table => "posts",
                     :scorer => "_score = -geo_distance(location, \"35.68138194x139.766083888889\")",
                   },
                   scorer("-geo_distance(%{column}, %{point})",
                           column: :location, point: "35.68138194x139.766083888889"))
    end

    test("Numeric") do
      assert_equal({
                     :table => "posts",
                     :scorer => "_score = 29",
                   },
                   scorer("_score = %{value}",
                          :value => 29))
    end
  end
end
