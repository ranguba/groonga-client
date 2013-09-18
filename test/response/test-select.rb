# Copyright (C) 2013  Kouhei Sutou <kou@clear-code.com>
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

class TestResponseSelect < Test::Unit::TestCase
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

      private
      def records(body)
        create_response(body).records
      end
    end

    class TestDrilldowns < self
      def setup
        pair_arguments = {
          "drilldown" => "_key",
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
        assert_equal(["_key"],
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

      private
      def drilldowns(body)
        create_response(body).drilldowns
      end
    end
  end
end
