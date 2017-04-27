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

class TestRequestSelectFilterEqualParmater < Test::Unit::TestCase
  def filter_parameter(column_name, value)
    Groonga::Client::Request::Select::FilterEqualParameter.new(column_name,
                                                               value)
  end

  def to_parameters(column_name, value)
    filter_parameter(column_name, value).to_parameters
  end

  sub_test_case("column name") do
    def test_string
      assert_equal({
                     :filter => "_key == 29",
                   },
                   to_parameters("_key", 29))
    end

    def test_symbol
      assert_equal({
                     :filter => "_key == 29",
                   },
                   to_parameters(:_key, 29))
    end
  end

  sub_test_case("value") do
    def test_string
      filter = <<-'FILTER'.strip
title == "[\"He\\ llo\"]"
      FILTER
      assert_equal({
                     :filter => filter,
                   },
                   to_parameters("title", "[\"He\\ llo\"]"))
    end

    sub_test_case("Symbol") do
      def test_id
        assert_equal({
                       :filter => "title == normalized_title",
                     },
                     to_parameters("title", :normalized_title))
      end

      def test_not_id
        assert_equal({
                       :filter => "title == \"Hello World\"",
                     },
                     to_parameters("title", :"Hello World"))
      end
    end

    def test_number
      assert_equal({
                     :filter => "age == 29",
                   },
                   to_parameters("age", 29))
    end

    def test_true
      assert_equal({
                     :filter => "published == true",
                   },
                   to_parameters("published", true))
    end

    def test_false
      assert_equal({
                     :filter => "published == false",
                   },
                   to_parameters("published", false))
    end
  end
end
