require "groonga/client"
require "test/unit/rr"

require "command/helper"

class TestCommandSelect < Test::Unit::TestCase
  include TestCommandHelper

  def setup
    @header = [0,1372430096.70991,0.000522851943969727]
    @body = [[[1], [["_id", "UInt32"]], [1]]]
  end

  def test_request
    client = open_client
    response = Groonga::Client::Response::Select.new(@header, @body)
    mock(client).execute_command("select", :table => :TestTable) do
      response
    end
    assert_equal(body, client.select(:table => :TestTable).body)
  end

  def test_response
    client = open_client
    stub(client.connection).send.with_any_args.yields([@header, @body].to_json) do
      request = Object.new
      stub(request).wait do
        true
      end
    end
    select = client.select(:table => :TestTable, :drilldown => "country,domain")
  end
end

