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
end

