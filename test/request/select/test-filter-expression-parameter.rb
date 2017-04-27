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

class TestRequestSelectFilterExpressionParmater < Test::Unit::TestCase
  def filter_parameter(expression, values=nil)
    Groonga::Client::Request::Select::FilterExpressionParameter.new(expression,
                                                                    values)
  end

  def to_parameters(expression, values=nil)
    filter_parameter(expression, values).to_parameters
  end

  sub_test_case("expression") do
    def test_nil
      assert_equal({},
                   to_parameters(nil))
    end

    def test_string
      assert_equal({
                     :filter => "age <= 20",
                   },
                   to_parameters("age <= 20"))
    end

    def test_empty_string
      assert_equal({},
                   to_parameters(""))
    end
  end

  sub_test_case("values") do
    def test_string
      filter = <<-'FILTER'.strip
title == "[\"He\\ llo\"]"
      FILTER
      assert_equal({
                     :filter => filter,
                   },
                   to_parameters("title == %{value}",
                                 :value => "[\"He\\ llo\"]"))
    end

    sub_test_case("Symbol") do
      def test_valid_id
        assert_equal({
                       :filter => "title == \"Hello\"",
                     },
                     to_parameters("%{column} == %{value}",
                                   :column => :title,
                                   :value => "Hello"))
      end

      def test_invalid_id
        assert_equal({
                       :filter => "title == \"Hello World\"",
                     },
                     to_parameters("title == %{value}",
                                   :value => :"Hello World"))
      end
    end

    def test_number
      assert_equal({
                     :filter => "age <= 29",
                   },
                   to_parameters("age <= %{value}",
                                 :value => 29))
    end

    def test_true
      assert_equal({
                     :filter => "published == true",
                   },
                   to_parameters("published == %{value}",
                                 :value => true))
    end

    def test_false
      assert_equal({
                     :filter => "published == false",
                   },
                   to_parameters("published == %{value}",
                                 :value => false))
    end

    def test_nil
      assert_equal({
                     :filter => "function(null)",
                   },
                   to_parameters("function(%{value})",
                                 :value => nil))
    end
  end
end
