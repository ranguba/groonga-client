require "groonga/client"
require "test/unit/rr"

class TestCommandSelect < Test::Unit::TestCase
  def test_request
    client = Groonga::Client.open(:protocol => :http)
    header = [0, 1372318932.42163, 0.000810809899121523]
    body = [[[1], [["_id", "UInt32"]], [1]]]
    response = Groonga::Client::Response::Select.new(header, body)
    mock(client).execute_command("select", :table => :Tests) do
      response
    end
    assert_equal(body, client.select(:table => :Tests).body)
  end

  def test_response
    client = Groonga::Client.open(:protocol => :http)
    header = [0,1372430096.70991,0.000522851943969727]
    body = [[[6],[["_id","UInt32"],["country","Country"]],[1,"japan"],[2,"brazil"],[3,"japan"],[4,"usa"],[5,"japan"],[6,"usa"]],
      [[3],[["_key","ShortText"],["_nsubrecs","Int32"]],["japan",3],["brazil",1],["usa",2]]]
    response = Groonga::Client::Response::Select.new(header, body)
    mock(client).execute_command("select", :table => :Test) do
      response
    end
    select = client.select(:table => :Test)

    assert_equal(6, select.total_records)
    expected_records = [
      {"_id"=>1, "country"=>"japan"},
      {"_id"=>2, "country"=>"brazil"},
      {"_id"=>3, "country"=>"japan"},
      {"_id"=>4, "country"=>"usa"},
      {"_id"=>5, "country"=>"japan"},
      {"_id"=>6, "country"=>"usa"},
    ]
    assert_equal(expected_records, select.records)

    assert_equal(3, select.total_drilldowns)
    expected_drilldowns = [
      {"_key"=>"japan", "_nsubrecs"=>3},
      {"_key"=>"brazil", "_nsubrecs"=>1},
      {"_key"=>"usa", "_nsubrecs"=>2},
    ]
    assert_equal(expected_drilldowns, select.drilldowns)
  end

  def test_response_limit_zero
    client = Groonga::Client.open(:protocol => :http)
    header = [0,1372430096.70991,0.000522851943969727]
    body = [[[6],[["_id","UInt32"],["country","Country"]]]]
    response = Groonga::Client::Response::Select.new(header, body)
    mock(client).execute_command("select", :table => :Test) do
      response
    end
    select = client.select(:table => :Test)

    assert_equal(6, select.total_records)
    assert_equal([], select.records)
  end
end

