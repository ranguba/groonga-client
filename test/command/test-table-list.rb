require "test/unit/rr"

require "command/helper"

class TestCommandTableList < Test::Unit::TestCase
  include TestCommandHelper

  def setup
    @header = [0,1372430096.70991,0.000522851943969727]
  end

  def test_request
    client = open_client
    header = @header
    body = [[["id","UInt32"],["name","ShortText"],["path","ShortText"],["flags","ShortText"],["domain","ShortText"],["range","ShortText"],["default_tokenizer","ShortText"],["normalizer","ShortText"]],
      [256,"Test","/tmp/test.db.0000100","TABLE_HASH_KEY|PERSISTENT",nil,nil,nil,nil]]
    response = Groonga::Client::Response::TableList.new(header, body)
    mock(client).execute_command("table_list", {}) do
      response
    end

    assert_equal(header, client.table_list.header)
  end

  def test_response
    client = open_client
    header = @header
    body = [[["id","UInt32"],["name","ShortText"],["path","ShortText"],["flags","ShortText"],["domain","ShortText"],["range","ShortText"],["default_tokenizer","ShortText"],["normalizer","ShortText"]],
      [256,"Test","/tmp/test.db.0000100","TABLE_HASH_KEY|PERSISTENT",nil,nil,nil,nil]]
    response = Groonga::Client::Response::TableList.new(header, body)
    mock(client).execute_command("table_list", {}) do
      response
    end

    table_list = client.table_list
    assert_equal(1, table_list.size)
    table_list.each do |table|
      assert_equal(Groonga::Client::Response::TableList::Table, table.class)
    end
  end
end

