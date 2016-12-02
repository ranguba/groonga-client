# Copyright (C) 2013-2016  Kouhei Sutou <kou@clear-code.com>
# Copyright (C) 2013  Kosuke Asami
# Copyright (C) 2016  Masafumi Yokoyama <yokoyama@clear-code.com>
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

class TestResponseSelectCommandVersion1 < Test::Unit::TestCase
  class TestParseRawResponse < self
    include TestResponseHelper

    def test_select
      header = [0,1372430096.70991,0.000522851943969727]
      body = [[[1], [["_id", "UInt32"]], [1]]]
      raw_response = [header, body].to_json

      response = parse_raw_response("select", raw_response)
      assert_equal(Groonga::Client::Response::Select, response.class)
    end
  end

  class TestBody < self
    def setup
      @command = Groonga::Command::Select.new("select", {})
    end

    def test_n_hits
      response = create_response([[[29], [["_id", "UInt32"]]]])
      assert_equal(29, response.n_hits)
    end

    private
    def create_response(body)
      header = [0, 1372430096.70991, 0.000522851943969727]
      Groonga::Client::Response::Select.new(@command, header, body)
    end

    class TestRecords < self
      def test_time
        updated_at = 1379040474
        assert_equal([{"updated_at" => Time.at(updated_at)}],
                     records([[[1], [["updated_at", "Time"]], [updated_at]]]))
      end

      def test_time_vector
        update1 = 1379040474
        update2 = 1464598349
        assert_equal([
                       {
                         "updates" => [
                           Time.at(update1),
                           Time.at(update2),
                         ],
                       },
                     ],
                     records([
                               [
                                 [1],
                                 [
                                   ["updates", "Time"],
                                 ],
                                 [
                                   [update1, update2],
                                 ],
                               ]
                             ]))
      end

      def test_duplicated_column_name
        assert_equal([
                       {
                         "html_escape"  => "content1",
                         "html_escape2" => "content2",
                         "html_escape3" => "content3",
                       }
                     ],
                     records([
                               [
                                 [1],
                                 [
                                   ["html_escape", nil],
                                   ["html_escape", nil],
                                   ["html_escape", nil],
                                 ],
                                 [
                                   "content1",
                                   "content2",
                                   "content3",
                                 ],
                               ]
                             ]))
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
        body = [
          [[0], []],
          [
            [29],
            [
              ["_key",      "ShortText"],
              ["_nsubrecs", "Int32"],
            ],
            ["groonga", 29],
            ["Ruby",    19],
            ["rroonga",  9],
          ],
        ]
        assert_equal(["tag"],
                     drilldowns(body).collect(&:key))
      end

      def test_n_hits
        body = [
          [[0], []],
          [
            [29],
            [
              ["_key",      "ShortText"],
              ["_nsubrecs", "Int32"],
            ],
            ["groonga", 29],
            ["Ruby",    19],
            ["rroonga",  9],
          ],
        ]
        assert_equal([29],
                     drilldowns(body).collect(&:n_hits))
      end

      def test_items
        body = [
          [[0], []],
          [
            [29],
            [
              ["_key",      "ShortText"],
              ["_nsubrecs", "Int32"],
            ],
            ["groonga", 29],
            ["Ruby",    19],
            ["rroonga",  9],
          ],
        ]
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

    class TestLabeledDrilldowns < self
      def setup
        pair_arguments = {
          "drilldowns[tag].keys" => "tag",
          "drilldowns[tag].output_columns" => "_key,_nsubrecs",
          "drilldowns[author].keys" => "author",
          "drilldowns[author].output_columns" => "_key,_nsubrecs",
        }
        @command = Groonga::Command::Select.new("select", pair_arguments)
      end

      def test_key
        body = [
          [[0], []],
          {
            "tag" => [
              [29],
              [
                ["_key",      "ShortText"],
                ["_nsubrecs", "Int32"],
              ],
              ["Groonga", 2],
              ["Ruby",    9],
              ["Rroonga", 1],
            ],
            "author" => [
              [4],
              [
                ["_key",      "ShortText"],
                ["_nsubrecs", "Int32"],
              ],
              ["Alice", 2],
              ["Bob",   1],
              ["Chris", 4],
            ],
          },
        ]
        assert_equal({
                       "tag" => "tag",
                       "author" => "author",
                     },
                     collect_values(body, &:key))
      end

      def test_n_hits
        body = [
          [[0], []],
          {
            "tag" => [
              [29],
              [
                ["_key",      "ShortText"],
                ["_nsubrecs", "Int32"],
              ],
              ["Groonga", 2],
              ["Ruby",    9],
              ["Rroonga", 1],
            ],
            "author" => [
              [4],
              [
                ["_key",      "ShortText"],
                ["_nsubrecs", "Int32"],
              ],
              ["Alice", 2],
              ["Bob",   1],
              ["Chris", 4],
            ],
          },
        ]
        assert_equal({
                       "tag" => 29,
                       "author" => 4,
                     },
                     collect_values(body, &:n_hits))
      end

      def test_items
        body = [
          [[0], []],
          {
            "tag" => [
              [29],
              [
                ["_key",      "ShortText"],
                ["_nsubrecs", "Int32"],
              ],
              ["Groonga", 2],
              ["Ruby",    9],
              ["Rroonga", 1],
            ],
            "author" => [
              [4],
              [
                ["_key",      "ShortText"],
                ["_nsubrecs", "Int32"],
              ],
              ["Alice", 2],
              ["Bob",   1],
              ["Chris", 4],
            ],
          },
        ]
        assert_equal({
                       "tag" => [
                         {"_key" => "Groonga", "_nsubrecs" => 2},
                         {"_key" => "Ruby",    "_nsubrecs" => 9},
                         {"_key" => "Rroonga", "_nsubrecs" => 1},
                       ],
                       "author" => [
                         {"_key" => "Alice", "_nsubrecs" => 2},
                         {"_key" => "Bob",   "_nsubrecs" => 1},
                         {"_key" => "Chris", "_nsubrecs" => 4},
                       ],
                     },
                     collect_values(body, &:items))
      end

      private
      def drilldowns(body)
        create_response(body).drilldowns
      end

      def collect_values(body)
        values = {}
        drilldowns(body).each do |label, drilldown|
          values[label] = yield(drilldown)
        end
        values
      end
    end

    class TestSlices < self
      def setup
        pair_arguments = {
          "slices[groonga].filter" => 'tag @ "groonga"',
        }
        @command = Groonga::Command::Select.new("select", pair_arguments)
        @body = [
          [
            [3],
            [
              [
                "_id",
                "UInt32"
              ],
              [
                "tag",
                "ShortText"
              ]
            ],
            [1, "groonga"],
            [2, "rroonga"],
            [3, "groonga"],
          ],
          {
            "groonga" => [
              [2],
              [
                [
                  "_id",
                  "UInt32"
                ],
                [
                  "tag",
                  "ShortText"
                ]
              ],
              [1, "groonga"],
              [3, "groonga"],
            ]
          }
        ]
      end

      def test_slices
        assert_equal({
                       "groonga" => [
                         {"_id" => 1, "tag" => "groonga"},
                         {"_id" => 3, "tag" => "groonga"},
                       ]
                     },
                     slices(@body))
      end

      private
      def slices(body)
        create_response(body).slices
      end
    end
  end
end
