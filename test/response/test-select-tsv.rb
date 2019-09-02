# Copyright (C) 2018-2019  Sutou Kouhei <kou@clear-code.com>
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

class TestResponseSelectTSV < Test::Unit::TestCase
  include TestResponseHelper

  def drilldown(label,
                keys,
                n_hits,
                records,
                raw_columns,
                raw_records)
    Groonga::Client::Response::Select::Drilldown.new(label,
                                                     keys,
                                                     n_hits,
                                                     records,
                                                     raw_columns,
                                                     raw_records)
  end

  def test_error
    raw_response = <<-TSV
-22	0	0.0	"message"	"function"	"file"	29

END
    TSV

    response = parse_raw_tsv_response("select", raw_response)
    assert_equal({
                   :return_code => -22,
                   :start_time => Time.at(0),
                   :elapsed_time => 0.0,
                   :error => {
                     :message => "message",
                     :function => "function",
                     :file => "file",
                     :line => 29,
                   },
                 },
                 {
                   :return_code => response.return_code,
                   :start_time => response.start_time,
                   :elapsed_time => response.elapsed_time,
                   :error => {
                     :message => response.message,
                     :function => response.function,
                     :file => response.file,
                     :line => response.line,
                   },
                 })
  end

  def test_basic
    raw_response = <<-TSV
 0	0	0.0
100
[	"_id"	"UInt32"	]
1
2
END
    TSV

    response = parse_raw_tsv_response("select", raw_response)
    assert_equal({
                   :return_code => 0,
                   :start_time => Time.at(0),
                   :elapsed_time => 0.0,
                   :records => [
                     {"_id" => "1"},
                     {"_id" => "2"},
                   ],
                 },
                 {
                   :return_code => response.return_code,
                   :start_time => response.start_time,
                   :elapsed_time => response.elapsed_time,
                   :records => response.records,
                 })
  end

  def test_drilldown
    raw_response = <<-TSV
 0	0	0.0
100
[	"_id"	"UInt32"	]
7
[	"_key"	"ShortText"	]	[	"_nsubrecs"	"UInt32"	]
"2.2.0"	"18044"
"2.3.0"	"18115"
"2.4.0"	"14594"
END
    TSV

    response = parse_raw_response_raw("select",
                                      {
                                        "drilldown" => "version",
                                        "output_type" => "tsv",
                                      },
                                      raw_response)
    drilldown_records = [
      {"_key" => "2.2.0", "_nsubrecs" => "18044"},
      {"_key" => "2.3.0", "_nsubrecs" => "18115"},
      {"_key" => "2.4.0", "_nsubrecs" => "14594"},
    ]
    assert_equal({
                   :return_code => 0,
                   :start_time => Time.at(0),
                   :elapsed_time => 0.0,
                   :records => [],
                   :drilldowns => [
                     drilldown("version",
                               ["version"],
                               7,
                               drilldown_records,
                               [
                                 ["_key", "ShortText"],
                                 ["_nsubrecs", "UInt32"],
                               ],
                               [
                                 ["2.2.0", "18044"],
                                 ["2.3.0", "18115"],
                                 ["2.4.0", "14594"],
                               ]),
                   ],
                 },
                 {
                   :return_code => response.return_code,
                   :start_time => response.start_time,
                   :elapsed_time => response.elapsed_time,
                   :records => response.records,
                   :drilldowns => response.drilldowns,
                 })
  end
end
