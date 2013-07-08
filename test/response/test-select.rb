require "response/helper"

class TestResponseSelect < Test::Unit::TestCase
  include TestResponseHelper

  def test_select
    header = [0,1372430096.70991,0.000522851943969727]
    body = [[[1], [["_id", "UInt32"]], [1]]]
    raw_response = [header, body].to_json

    response = parse_raw_response("select", raw_response)
    assert_equal(Groonga::Client::Response::Select, response.class)
  end
end
