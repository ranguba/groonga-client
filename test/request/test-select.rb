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

class TestRequestSelect < Test::Unit::TestCase
  setup do
    @request = Groonga::Client::Request::Select.new("posts")
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
                       :"drilldowns[label].offset" => 29,
                     },
                     drilldown.offset(29).to_parameters)
      end
    end

    sub_test_case("#limit") do
      test "Integer" do
        assert_equal({
                       :table => "posts",
                       :"drilldowns[label].limit" => 29,
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
end
