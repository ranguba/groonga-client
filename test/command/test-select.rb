require "groonga/client"
require "test/unit/rr"

require "command/helper"

class TestCommandSelect < Test::Unit::TestCase
  include TestCommandHelper

  def setup
    @header = [0,1372430096.70991,0.000522851943969727]
  end

  def test_request
    client = open_client
    header = @header
    body = [[[1], [["_id", "UInt32"]], [1]]]
    response = Groonga::Client::Response::Select.new(header, body)
    mock(client).execute_command("select", :table => :TestTable) do
      response
    end
    assert_equal(body, client.select(:table => :TestTable).body)
  end

  def test_response
    client = open_client
    header = @header

    body = [[[6],[["_id","UInt32"],["country","Country"],["domain","Domain"]],[1,"japan",".com"],[2,"brazil",".com"],[3,"japan",".org"],[4,"usa",".com"],[5,"japan",".org"],[6,"usa",".com"]],
      [[3],[["_key","ShortText"],["_nsubrecs","Int32"]],["japan",3],["brazil",1],["usa",2]],
      [[2],[["_key","ShortText"],["_nsubrecs","Int32"]],[".com",4],[".org",2]]]
    stub(client.connection).send.with_any_args.yields([header, body].to_json) do
      request = Object.new
      stub(request).wait do
        true
      end
    end
    select = client.select(:table => :TestTable, :drilldown => "country,domain")

    assert_equal(6, select.n_records)
    expected_records = [
      {"_id"=>1, "country"=>"japan", "domain"=>".com"},
      {"_id"=>2, "country"=>"brazil", "domain"=>".com"},
      {"_id"=>3, "country"=>"japan", "domain"=>".org"},
      {"_id"=>4, "country"=>"usa", "domain"=>".com"},
      {"_id"=>5, "country"=>"japan", "domain"=>".org"},
      {"_id"=>6, "country"=>"usa", "domain"=>".com"},
    ]
    assert_equal(expected_records, select.records)

    assert_equal(3, select.drilldowns.first.n_hits)
    expected_drilldowns = [
      {"_key"=>"japan", "_nsubrecs"=>3},
      {"_key"=>"brazil", "_nsubrecs"=>1},
      {"_key"=>"usa", "_nsubrecs"=>2},
    ]
    assert_equal(expected_drilldowns, select.drilldowns.first.items)
  end

  def test_response_limit_zero
    client = open_client
    header = @header
    body = [[[6],[["_id","UInt32"],["country","Country"]]]]
    response = Groonga::Client::Response::Select.new(header, body)
    mock(client).execute_command("select", :table => :TestTable) do
      response
    end
    select = client.select(:table => :TestTable)

    assert_equal(6, select.n_records)
    assert_equal([], select.records)
  end
end

