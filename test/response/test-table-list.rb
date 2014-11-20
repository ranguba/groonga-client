require "response/helper"

class TestResponseTableList < Test::Unit::TestCase
  include TestResponseHelper

  def test_table_list
    header = [
      0,
      1372430096.70991,
      0.000522851943969727,
    ]
    columns = [
      ["id",                "UInt32"],
      ["name",              "ShortText"],
      ["path",              "ShortText"],
      ["flags",             "ShortText"],
      ["domain",            "ShortText"],
      ["range",             "ShortText"],
      ["default_tokenizer", "ShortText"],
      ["normalizer",        "ShortText"],
    ]
    body = [
      columns,
      [
        256,
        "Test",
        "/tmp/test.db.0000100",
        "TABLE_HASH_KEY|PERSISTENT",
        nil,
        nil,
        nil,
        nil,
      ],
    ]
    raw_response = [header, body].to_json

    response = parse_raw_response("table_list", raw_response)
    assert_equal(Groonga::Client::Response::TableList, response.class)
  end
end
