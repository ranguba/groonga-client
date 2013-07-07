require "test/unit/rr"

require "response/helper"

class TestResponseColumnList < Test::Unit::TestCase
  include TestResponseHelper

  def test_column_list
    header = [0,1372430096.70991,0.000522851943969727]
    body = [[["id","UInt32"],["name","ShortText"],["path","ShortText"],["type","ShortText"],["flags","ShortText"],["domain","ShortText"],["range","ShortText"],["source","ShortText"]],
      [256,"Text","/tmp/test.db.0000100","var","COLUMN_SCALAR|PERSISTENT","TestTable","ShortText",[]]]

    connection = Groonga::Client::Protocol::HTTP.new({})
    stub(connection).send.with_any_args.yields([header, body].to_json) do
      request = Object.new
      stub(request).wait do
        true
      end
    end

    response = make_command("column_list").execute(connection)
    assert_equal(Groonga::Client::Response::ColumnList, response.class)
  end
end

