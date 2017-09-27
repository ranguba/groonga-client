# Copyright (C) 2017  Kouhei Sutou <kou@clear-code.com>
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

class TestResponseSelectXML < Test::Unit::TestCase
  include TestResponseHelper

  def drilldown(key, n_hits, records)
    Groonga::Client::Response::Select::Drilldown.new(key, n_hits, records)
  end

  def test_basic
    raw_response = <<-XML
<?xml version="1.0" encoding="utf-8"?>
<SEGMENTS>
<SEGMENT>
<RESULTPAGE>
<RESULTSET OFFSET="0" LIMIT="1" NHITS="100">
<HIT NO="1">
<FIELD NAME="_id">1</FIELD>
</HIT>
</RESULTSET>
</RESULTPAGE>
</SEGMENT>
</SEGMENTS>
    XML

    response = parse_raw_xml_response("select", raw_response)
    assert_equal({
                   :return_code => 0,
                   :start_time => Time.at(0),
                   :elapsed_time => 0.0,
                   :records => [{"_id" => "1"}],
                 },
                 {
                   :return_code => response.return_code,
                   :start_time => response.start_time,
                   :elapsed_time => response.elapsed_time,
                   :records => response.records,
                 })
  end

  def test_drilldown
    raw_response = <<-XML
<?xml version="1.0" encoding="utf-8"?>
<SEGMENTS>
<SEGMENT>
<RESULTPAGE>
<RESULTSET OFFSET="0" LIMIT="0" NHITS="100">
</RESULTSET>
<NAVIGATIONENTRY>
<NAVIGATIONELEMENTS COUNT="7">
<NAVIGATIONELEMENT _key="2.2.0" _nsubrecs="18044" />
<NAVIGATIONELEMENT _key="2.3.0" _nsubrecs="18115" />
<NAVIGATIONELEMENT _key="2.4.0" _nsubrecs="14594" />
</NAVIGATIONELEMENTS>
</NAVIGATIONENTRY>
</RESULTPAGE>
</SEGMENT>
</SEGMENTS>
    XML

    response = parse_raw_response_raw("select",
                                      {
                                        "drilldown" => "version",
                                        "output_type" => "xml",
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
                     drilldown("version", 7, drilldown_records),
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
