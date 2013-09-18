require "test/unit/rr"

class TestResultsTableList < Test::Unit::TestCase
  def setup
    command = nil
    header = [0,1372430096.70991,0.000522851943969727]
    body = [[["id","UInt32"],["name","ShortText"],["path","ShortText"],["flags","ShortText"],["domain","ShortText"],["range","ShortText"],["default_tokenizer","ShortText"],["normalizer","ShortText"]],
      [257,"Ages","/tmp/test.db.0000101","TABLE_DAT_KEY|PERSISTENT","UInt32",nil,nil,nil],
      [256,"Lexicon","/tmp/test.db.0000100","TABLE_PAT_KEY|PERSISTENT","ShortText",nil,"TokenBigram","NormalizerAuto"],
      [258,"Logs","/tmp/test.db.0000102","TABLE_NO_KEY|PERSISTENT",nil,nil,nil,nil]]
    @table_list = Groonga::Client::Response::TableList.new(command, header, body)
  end

  def test_table_list
    assert_equal(
      [
        {
          :id => 257,
          :name => "Ages",
          :path => "/tmp/test.db.0000101",
          :flags => "TABLE_DAT_KEY|PERSISTENT",
          :domain => "UInt32",
          :range => nil,
          :default_tokenizer => nil,
          :normalizer => nil,
        },
        {
          :id => 256,
          :name => "Lexicon",
          :path => "/tmp/test.db.0000100",
          :flags => "TABLE_PAT_KEY|PERSISTENT",
          :domain => "ShortText",
          :range => nil,
          :default_tokenizer => "TokenBigram",
          :normalizer => "NormalizerAuto"
        },
        {
          :id => 258,
          :name => "Logs",
          :path => "/tmp/test.db.0000102",
          :flags => "TABLE_NO_KEY|PERSISTENT",
          :domain => nil,
          :range => nil,
          :default_tokenizer => nil,
          :normalizer => nil
        },
      ],
      @table_list.collect {|table|
        {
          :id => table.id,
          :name => table.name,
          :path => table.path,
          :flags => table.flags,
          :domain => table.domain,
          :range => table.range,
          :default_tokenizer => table.default_tokenizer,
          :normalizer => table.normalizer,
        }
      }
    )
  end
end

