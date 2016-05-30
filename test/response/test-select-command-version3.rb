# Copyright (C) 2013-2016  Kouhei Sutou <kou@clear-code.com>
# Copyright (C) 2013  Kosuke Asami
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

class TestResponseSelectCommandVersion3 < Test::Unit::TestCase
  class TestParseRawResponse < self
    include TestResponseHelper

    def test_select
      header = {
        "return_code"  => 0,
        "start_time"   => 1372430096.70991,
        "elapsed_time" => 0.000522851943969727,
      }
      body = {
        "n_hits" => 1,
        "columns" => [
          {
            "name" => "_id",
            "type" => "UInt32",
          },
        ],
        "records" => [
          1,
        ],
      }
      raw_response = {
        "header" => header,
        "body"   => body,
      }.to_json

      response = parse_raw_response("select", raw_response)
      assert_equal(Groonga::Client::Response::Select, response.class)
    end
  end

  class TestBody < self
    def setup
      @command = Groonga::Command::Select.new("select", {})
    end

    def test_n_hits
      response = create_response({
                                   "n_hits" => 29,
                                   "columns" => [
                                     {
                                       "name" => "_id",
                                       "type" => "UInt32",
                                     },
                                   ],
                                   "records" => [
                                   ],
                                 })
      assert_equal(29, response.n_hits)
    end

    private
    def create_response(body)
      header = {
        "return_code"  => 0,
        "start_time"   => 1372430096.70991,
        "elapsed_time" => 0.000522851943969727,
      }
      Groonga::Client::Response::Select.new(@command, header, body)
    end

    class TestRecords < self
      def test_time
        updated_at = 1379040474
        assert_equal([{"updated_at" => Time.at(updated_at)}],
                     records({
                               "n_hits" => 1,
                               "columns" => [
                                 {
                                   "name" => "updated_at",
                                   "type" => "Time",
                                 },
                               ],
                               "records" => [
                                 [updated_at],
                               ],
                             }))
      end

      def test_duplicated_column_name
        assert_equal([
                       {
                         "html_escape"  => "content1",
                         "html_escape2" => "content2",
                         "html_escape3" => "content3",
                       }
                     ],
                     records({
                               "n_hits" => 1,
                               "columns" => [
                                 {
                                   "name" => "html_escape",
                                   "type" => nil,
                                 },
                                 {
                                   "name" => "html_escape",
                                   "type" => nil,
                                 },
                                 {
                                   "name" => "html_escape",
                                   "type" => nil,
                                 }
                               ],
                               "records" => [
                                 ["content1", "content2", "content3"],
                               ],
                             }))
      end

      private
      def records(body)
        create_response(body).records
      end
    end

    class TestDrilldowns < self
      def setup
        pair_arguments = {
          "drilldown" => "tag",
          "drilldown_output_columns" => "_key,_nsubrecs",
        }
        @command = Groonga::Command::Select.new("select", pair_arguments)
      end

      def test_key
        body = {
          "n_hits" => 0,
          "columns" => [],
          "records" => [],
          "drilldowns" => {
            "tag" => {
              "n_hits" => 29,
              "columns" => [
                {
                  "name" => "_key",
                  "type" => "ShortText",
                },
                {
                  "name" => "_nsubrecs",
                  "type" => "Int32",
                },
              ],
              "records" => [
                ["groonga", 29],
                ["Ruby",    19],
                ["rroonga",  9],
              ],
            },
          },
        }
        assert_equal(["tag"],
                     drilldowns(body).collect(&:key))
      end

      def test_n_hits
        body = {
          "n_hits" => 0,
          "columns" => [],
          "records" => [],
          "drilldowns" => {
            "tag" => {
              "n_hits" => 29,
              "columns" => [
                {
                  "name" => "_key",
                  "type" => "ShortText",
                },
                {
                  "name" => "_nsubrecs",
                  "type" => "Int32",
                },
              ],
              "records" => [
                ["groonga", 29],
                ["Ruby",    19],
                ["rroonga",  9],
              ],
            },
          },
        }
        assert_equal([29],
                     drilldowns(body).collect(&:n_hits))
      end

      def test_items
        body = {
          "n_hits" => 0,
          "columns" => [],
          "records" => [],
          "drilldowns" => {
            "tag" => {
              "n_hits" => 29,
              "columns" => [
                {
                  "name" => "_key",
                  "type" => "ShortText",
                },
                {
                  "name" => "_nsubrecs",
                  "type" => "Int32",
                },
              ],
              "records" => [
                ["groonga", 29],
                ["Ruby",    19],
                ["rroonga",  9],
              ],
            },
          },
        }
        assert_equal([
                       [
                         {"_key" => "groonga", "_nsubrecs" => 29},
                         {"_key" => "Ruby",    "_nsubrecs" => 19},
                         {"_key" => "rroonga", "_nsubrecs" =>  9},
                       ],
                     ],
                     drilldowns(body).collect(&:items))
      end

      private
      def drilldowns(body)
        create_response(body).drilldowns
      end
    end
  end
end
