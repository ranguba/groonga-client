require "test/unit/rr"

class TestResultsSelect < Test::Unit::TestCase
  class TestResults < self
    def setup
      header = [0,1372430096.70991,0.000522851943969727]
      body = [[[6],[["_id","UInt32"],["country","Country"],["domain","Domain"]],[1,"japan",".com"],[2,"brazil",".com"],[3,"japan",".org"],[4,"usa",".com"],[5,"japan",".org"],[6,"usa",".com"]],
        [[3],[["_key","ShortText"],["_nsubrecs","Int32"]],["japan",3],["brazil",1],["usa",2]],
        [[2],[["_key","ShortText"],["_nsubrecs","Int32"]],[".com",4],[".org",2]]]
      @select = Groonga::Client::Response::Select.new(header, body)
    end

    def test_n_records
      assert_equal(6, @select.n_records)
    end

    def test_records
      expected_records = [
        {"_id"=>1, "country"=>"japan", "domain"=>".com"},
        {"_id"=>2, "country"=>"brazil", "domain"=>".com"},
        {"_id"=>3, "country"=>"japan", "domain"=>".org"},
        {"_id"=>4, "country"=>"usa", "domain"=>".com"},
        {"_id"=>5, "country"=>"japan", "domain"=>".org"},
        {"_id"=>6, "country"=>"usa", "domain"=>".com"},
      ]
      assert_equal(expected_records, @select.records)
    end

    def test_drilldowns
      expected_drilldowns = [
        Drilldown.new(3, [
            {"_key"=>"japan", "_nsubrecs"=>3},
            {"_key"=>"brazil", "_nsubrecs"=>1},
            {"_key"=>"usa", "_nsubrecs"=>2},]),
        Drilldown.new(2, [
            {"_key"=>".com", "_nsubrecs"=>4},
            {"_key"=>".org", "_nsubrecs"=>2}]),
      ]
      assert_equal(expected_drilldowns, @select.drilldowns.collect{|drilldown|
          Drilldown.new(drilldown.n_hits, drilldown.items)
        })
    end
  end

  class TestNoRecordsBody < self
    def setup
      header = [0,1372430096.70991,0.000522851943969727]
      body = [[[6],[["_id","UInt32"],["country","Country"]]]]
      @select = Groonga::Client::Response::Select.new(header, body)
    end

    def test_n_records
      assert_equal(6, @select.n_records)
    end

    def test_records
      assert_equal([], @select.records)
    end
  end

  Drilldown = Struct.new(:n_hits, :items)
end

