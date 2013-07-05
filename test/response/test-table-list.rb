require "test/unit/rr"

require "response/helper"

class TestResponseTableList < Test::Unit::TestCase
  include TestResponseHelper

  def test_table_list
    header = [0,1372430096.70991,0.000522851943969727]
    body = [[["id","UInt32"],["name","ShortText"],["path","ShortText"],["flags","ShortText"],["domain","ShortText"],["range","ShortText"],["default_tokenizer","ShortText"],["normalizer","ShortText"]],
      [256,"Test","/tmp/test.db.0000100","TABLE_HASH_KEY|PERSISTENT",nil,nil,nil,nil]]

    connection = Groonga::Client::Protocol::HTTP.new({})
    stub(connection).send.with_any_args.yields([header, body].to_json) do
      request = Object.new
      stub(request).wait do
        true
      end
    end

    response = make_command("table_list").execute(connection)
    assert_equal(Groonga::Client::Response::TableList, response.class)
  end
end
