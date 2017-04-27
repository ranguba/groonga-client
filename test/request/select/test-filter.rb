# Copyright (C) 2016-2017  Kouhei Sutou <kou@clear-code.com>
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

class TestRequestSelectFilter < Test::Unit::TestCase
  setup do
    @request = Groonga::Client::Request::Select.new("posts")
  end

  def filter(*args)
    @request.filter(*args).to_parameters
  end

  sub_test_case("expression") do
    def test_nil
      assert_equal({
                     :table => "posts",
                   },
                   filter(nil))
    end

    def test_string
      assert_equal({
                     :table => "posts",
                     :filter => "age <= 20",
                   },
                   filter("age <= 20"))
    end

    def test_empty_string
      assert_equal({
                     :table => "posts",
                   },
                   filter(""))
    end
  end

  sub_test_case("values") do
    test("String") do
      filter = <<-'FILTER'.strip
title == "[\"He\\ llo\"]"
      FILTER
      assert_equal({
                     :table => "posts",
                     :filter => filter,
                   },
                   filter("title == %{value}",
                          :value => "[\"He\\ llo\"]"))
    end

    sub_test_case("Symbol") do
      test("valid ID") do
        assert_equal({
                       :table => "posts",
                       :filter => "title == \"Hello\"",
                     },
                     filter("%{column} == %{value}",
                            :column => :title,
                            :value => "Hello"))
      end

      test("invalid ID") do
        assert_equal({
                       :table => "posts",
                       :filter => "title == \"Hello World\"",
                     },
                     filter("title == %{value}",
                            :value => :"Hello World"))
      end
    end

    test("Numeric") do
      assert_equal({
                     :table => "posts",
                     :filter => "age <= 29",
                   },
                   filter("age <= %{value}",
                          :value => 29))
    end

    test("true") do
      assert_equal({
                     :table => "posts",
                     :filter => "published == true",
                   },
                   filter("published == %{value}",
                          :value => true))
    end

    test("false") do
      assert_equal({
                     :table => "posts",
                     :filter => "published == false",
                   },
                   filter("published == %{value}",
                          :value => false))
    end

    test("nil") do
      assert_equal({
                     :table => "posts",
                     :filter => "function(null)",
                   },
                   filter("function(%{value})",
                          :value => nil))
    end

    test("Array") do
      assert_equal({
                     :table => "posts",
                     :filter => "function([\"a\", 29])",
                   },
                   filter("function(%{arg})", :arg => ["a", 29]))
    end

    test("Hash") do
      assert_equal({
                     :table => "posts",
                     :filter => "function({\"string\": \"value\", \"number\": 29})",
                   },
                   filter("function(%{options})",
                          :options => {
                            "string" => "value",
                            "number" => 29
                          }))
    end
  end

  sub_test_case("column name") do
    test("String") do
      assert_equal({
                     :table => "posts",
                     :filter => "_key == 29",
                   },
                   filter("_key", 29))
    end

    test("Symbol") do
      assert_equal({
                     :table => "posts",
                     :filter => "_key == 29",
                   },
                   filter(:_key, 29))
    end
  end

  sub_test_case("value") do
    test("String") do
      filter = <<-'FILTER'.strip
title == "[\"He\\ llo\"]"
      FILTER
      assert_equal({
                     :table => "posts",
                     :filter => filter,
                   },
                   filter("title", "[\"He\\ llo\"]"))
    end

    sub_test_case("Symbol") do
      test("valid ID") do
        assert_equal({
                       :table => "posts",
                       :filter => "title == normalized_title",
                     },
                     filter("title", :normalized_title))
      end

      test("invalid ID") do
        assert_equal({
                       :table => "posts",
                       :filter => "title == \"Hello World\"",
                     },
                     filter("title", :"Hello World"))
      end
    end

    test("Numeric") do
      assert_equal({
                     :table => "posts",
                     :filter => "age == 29",
                   },
                   filter("age", 29))
    end

    test("true") do
      assert_equal({
                     :table => "posts",
                     :filter => "published == true",
                   },
                   filter("published", true))
    end

    test("false") do
      assert_equal({
                     :table => "posts",
                     :filter => "published == false",
                   },
                   filter("published", false))
    end
  end

  sub_test_case("Filter") do
    sub_test_case("#geo_in_circle") do
      def geo_in_circle(*args)
        @request.filter.geo_in_circle(*args).to_parameters
      end

      test("column") do
        assert_equal({
                       :table => "posts",
                       :filter => "geo_in_circle(location, \"140x250\", 300, \"rectangle\")",
                     },
                     geo_in_circle(:location, "140x250", 300))
      end

      test("point") do
        assert_equal({
                       :table => "posts",
                       :filter => "geo_in_circle(\"100x100\", \"140x250\", 300, \"rectangle\")",
                     },
                     geo_in_circle("100x100", "140x250", 300))
      end

      test("approximate type") do
        assert_equal({
                       :table => "posts",
                       :filter => "geo_in_circle(\"100x100\", \"140x250\", 300, \"sphere\")",
                     },
                     geo_in_circle("100x100", "140x250", 300, "sphere"))
      end
    end

    sub_test_case("#between") do
      def between(column_name,
                  min, min_border,
                  max, max_border)
        @request.filter.between(column_name,
                                min, min_border,
                                max, max_border).to_parameters
      end

      test("border") do
        assert_equal({
                       :table => "posts",
                       :filter => "between(ages, 2, \"include\", 29, \"exclude\")",
                     },
                     between(:ages, 2, "include", 29, "exclude"))
      end
    end

    sub_test_case("#in_values") do
      def in_values(column_name, *values)
        @request.filter.in_values(column_name, *values).to_parameters
      end

      test("numbers") do
        assert_equal({
                       :table => "posts",
                       :filter => "in_values(ages, 2, 29)",
                     },
                     in_values(:ages, 2, 29))
      end

      test("strings") do
        assert_equal({
                       :table => "posts",
                       :filter => "in_values(tags, \"groonga\", \"have \\\"double\\\" quote\")",
                     },
                     in_values(:tags, "groonga", "have \"double\" quote"))
      end

      test("no values") do
        assert_equal({
                       :table => "posts",
                     },
                     in_values(:tags))
      end
    end
  end
end
