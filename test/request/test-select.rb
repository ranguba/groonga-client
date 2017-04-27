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

class TestRequestSelect < Test::Unit::TestCase
  setup do
    @request = Groonga::Client::Request::Select.new("posts")
  end

  sub_test_case("#filter") do
    def filter(*args)
      @request.filter(*args).to_parameters
    end

    test("Numeric") do
      assert_equal({
                     :table => "posts",
                     :filter => "rate == 5",
                   },
                   filter("rate == %{rate}", :rate => 5))
    end

    test("true") do
      assert_equal({
                     :table => "posts",
                     :filter => "published == true",
                   },
                   filter("published == %{published}", :published => true))
    end

    test("false") do
      assert_equal({
                     :table => "posts",
                     :filter => "published == false",
                   },
                   filter("published == %{published}", :published => false))
    end

    test("nil") do
      assert_equal({
                     :table => "posts",
                     :filter => "function(null)",
                   },
                   filter("function(%{arg})", :arg => nil))
    end

    test("String") do
      assert_equal({
                     :table => "posts",
                     :filter => "title == \"Hello\"",
                   },
                   filter("title == %{title}", :title => "Hello"))
    end

    test("Symbol") do
      assert_equal({
                     :table => "posts",
                     :filter => "title == \"Hello\"",
                   },
                   filter("%{column} == %{value}",
                          :column => :title,
                          :value => "Hello"))
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
                     between("ages", 2, "include", 29, "exclude"))
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
                     in_values("ages", 2, 29))
      end

      test("strings") do
        assert_equal({
                       :table => "posts",
                       :filter => "in_values(tags, \"groonga\", \"have \\\"double\\\" quote\")",
                     },
                     in_values("tags", "groonga", "have \"double\" quote"))
      end

      test("no values") do
        assert_equal({
                       :table => "posts",
                     },
                     in_values("tags"))
      end
    end
  end

  sub_test_case("#drilldowns") do
    def drilldown
      @request.drilldowns("label")
    end

    sub_test_case("#keys") do
      test "String" do
        assert_equal({
                       :table => "posts",
                       :"drilldowns[label].keys" => "tag",
                     },
                     drilldown.keys("tag").to_parameters)
      end

      test "Array" do
        assert_equal({
                       :table => "posts",
                       :"drilldowns[label].keys" => "start, end",
                     },
                     drilldown.keys(["start", "end"]).to_parameters)
      end
    end

    sub_test_case("#sort_keys") do
      test "String" do
        assert_equal({
                       :table => "posts",
                       :"drilldowns[label].sort_keys" => "-_nsubrecs",
                       :"drilldowns[label].sortby"    => "-_nsubrecs",
                     },
                     drilldown.sort_keys("-_nsubrecs").to_parameters)
      end

      test "Array" do
        assert_equal({
                       :table => "posts",
                       :"drilldowns[label].sort_keys" => "-_nsubrecs, name",
                       :"drilldowns[label].sortby"    => "-_nsubrecs, name",
                     },
                     drilldown.sort_keys(["-_nsubrecs", "name"]).to_parameters)
      end
    end

    sub_test_case("#output_columns") do
      test "String" do
        assert_equal({
                       :table => "posts",
                       :"drilldowns[label].output_columns" => "_key, -_nsubrecs",
                     },
                     drilldown.output_columns("_key, -_nsubrecs").to_parameters)
      end

      test "Array" do
        assert_equal({
                       :table => "posts",
                       :"drilldowns[label].output_columns" => "_key, -_nsubrecs",
                     },
                     drilldown.output_columns(["_key, -_nsubrecs"]).to_parameters)
      end
    end

    sub_test_case("#offset") do
      test "Integer" do
        assert_equal({
                       :table => "posts",
                       :"drilldowns[label].offset" => "29",
                     },
                     drilldown.offset(29).to_parameters)
      end
    end

    sub_test_case("#limit") do
      test "Integer" do
        assert_equal({
                       :table => "posts",
                       :"drilldowns[label].limit" => "29",
                     },
                     drilldown.limit(29).to_parameters)
      end
    end

    sub_test_case("#calc_types") do
      test "String" do
        assert_equal({
                       :table => "posts",
                       :"drilldowns[label].calc_types" => "COUNT|AVG",
                     },
                     drilldown.calc_types("COUNT|AVG").to_parameters)
      end

      test "Array" do
        assert_equal({
                       :table => "posts",
                       :"drilldowns[label].calc_types" => "COUNT|AVG",
                     },
                     drilldown.calc_types(["COUNT", "AVG"]).to_parameters)
      end
    end

    sub_test_case("#calc_target") do
      test "Symbol" do
        assert_equal({
                       :table => "posts",
                       :"drilldowns[label].calc_target" => "rank",
                     },
                     drilldown.calc_target(:rank).to_parameters)
      end
    end
  end

  sub_test_case("#columns") do
    def column
      @request.columns("label")
    end

    test "#stage" do
      assert_equal({
                     :table => "posts",
                     :"columns[label].stage" => "output",
                   },
                   column.stage("output").to_parameters)
    end

    test "#type" do
      assert_equal({
                     :table => "posts",
                     :"columns[label].type" => "Text",
                   },
                   column.type("Text").to_parameters)
    end

    test "#flags" do
      assert_equal({
                     :table => "posts",
                     :"columns[label].flags" => "COLUMN_SCALAR|COMPRESS_LZ4",
                   },
                   column.flags(["COLUMN_SCALAR", "COMPRESS_LZ4"]).to_parameters)
    end

    test "#value" do
      assert_equal({
                     :table => "posts",
                     :"columns[label].value" => "highlight_html(\"xxx\")",
                   },
                   column.value("highlight_html(%{text})", text: "xxx").to_parameters)
    end

    sub_test_case("#window") do
      test "#sort_keys" do
        assert_equal({
                       :table => "posts",
                       :"columns[label].window.sort_keys" => "_id",
                     },
                     column.window.sort_keys("_id").to_parameters)
      end

      test "#group_keys" do
        assert_equal({
                       :table => "posts",
                       :"columns[label].window.group_keys" => "day, tag",
                     },
                     column.window.group_keys(["day", "tag"]).to_parameters)
      end
    end
  end

  sub_test_case("#paginate") do
    def paginate(*args)
      @request.paginate(*args).to_parameters
    end

    sub_test_case("page") do
      test("nil") do
        assert_equal({
                       :table  => "posts",
                       :offset => "0",
                       :limit  => "10",
                     },
                     paginate(nil))
      end

      test("0") do
        assert_equal({
                       :table  => "posts",
                       :offset => "0",
                       :limit  => "10",
                     },
                     paginate(0))
      end

      test("1") do
        assert_equal({
                       :table  => "posts",
                       :offset => "0",
                       :limit  => "10",
                     },
                     paginate(1))
      end

      test("positive") do
        assert_equal({
                       :table  => "posts",
                       :offset => "80",
                       :limit  => "10",
                     },
                     paginate(9))
      end

      test("negative") do
        assert_equal({
                       :table  => "posts",
                       :offset => "0",
                       :limit  => "10",
                     },
                     paginate(-1))
      end

      test("string") do
        assert_equal({
                       :table  => "posts",
                       :offset => "80",
                       :limit  => "10",
                     },
                     paginate("9"))
      end
    end

    sub_test_case("paginate") do
      test("default") do
        assert_equal({
                       :table  => "posts",
                       :offset => "20",
                       :limit  => "10",
                     },
                     paginate(3))
      end

      test("nil") do
        assert_equal({
                       :table  => "posts",
                       :offset => "20",
                       :limit  => "10",
                     },
                     paginate(3, per_page: nil))
      end

      test("0") do
        assert_equal({
                       :table  => "posts",
                       :offset => "20",
                       :limit  => "10",
                     },
                     paginate(3, per_page: 0))
      end

      test("1") do
        assert_equal({
                       :table  => "posts",
                       :offset => "2",
                       :limit  => "1",
                     },
                     paginate(3, per_page: 1))
      end

      test("positive") do
        assert_equal({
                       :table  => "posts",
                       :offset => "58",
                       :limit  => "29",
                     },
                     paginate(3, per_page: 29))
      end

      test("negative") do
        assert_equal({
                       :table  => "posts",
                       :offset => "20",
                       :limit  => "10",
                     },
                     paginate(3, per_page: -1))
      end

      test("string") do
        assert_equal({
                       :table  => "posts",
                       :offset => "58",
                       :limit  => "29",
                     },
                     paginate(3, per_page: "29"))
      end
    end
  end
end
