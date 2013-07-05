require "test/unit/rr"

require "response/helper"

class TestResponseSelect < Test::Unit::TestCase
  include TestResponseHelper

  def test_select
    header = [0,1372430096.70991,0.000522851943969727]
    body = [[[1], [["_id", "UInt32"]], [1]]]

    connection = Groonga::Client::Protocol::HTTP.new({})
    stub(connection).send.with_any_args.yields([header, body].to_json) do
      request = Object.new
      stub(request).wait do
        true
      end
    end

    response = make_command("select").execute(connection)
    assert_equal(Groonga::Client::Response::Select, response.class)
  end
end
