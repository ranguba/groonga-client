require "test/unit/rr"

class TestResultsColumnList < Test::Unit::TestCase
  class TestResults < self
    def setup
      command = nil
      header = [0,1372430096.70991,0.000522851943969727]
      body = [[["id","UInt32"],["name","ShortText"],["path","ShortText"],["type","ShortText"],["flags","ShortText"],["domain","ShortText"],["range","ShortText"],["source","ShortText"]],
        [259,"_key","","","COLUMN_SCALAR","Bigram","ShortText",[]],
        [278,"comment_index","/tmp/db.db.0000116","index","COLUMN_INDEX|WITH_POSITION|PERSISTENT","Bigram","Comments",["Comments.comment"]],
        [277,"users_index","/tmp/db.db.0000115","index","COLUMN_INDEX|WITH_SECTION|WITH_POSITION|PERSISTENT","Bigram","Users",["Users.name","Users.location_str","Users.description"]]]
      @column_list = Groonga::Client::Response::ColumnList.new(command, header, body)
    end

    def test_column_list
      assert_equal(
        [
          {
            :id => 259,
            :name => "_key",
            :path => "",
            :type => "",
            :flags => "COLUMN_SCALAR",
            :domain => "Bigram",
            :range => "ShortText",
            :source => [],
          },
          {
            :id => 278,
            :name => "comment_index",
            :path => "/tmp/db.db.0000116",
            :type => "index",
            :flags => "COLUMN_INDEX|WITH_POSITION|PERSISTENT",
            :domain => "Bigram",
            :range => "Comments",
            :source => ["Comments.comment"],
          },
          {
            :id => 277,
            :name => "users_index",
            :path => "/tmp/db.db.0000115",
            :type => "index",
            :flags => "COLUMN_INDEX|WITH_SECTION|WITH_POSITION|PERSISTENT",
            :domain => "Bigram",
            :range => "Users",
            :source => ["Users.name","Users.location_str", "Users.description"],
          },
        ],
        @column_list.collect {|column|
          {
            :id => column.id,
            :name => column.name,
            :path => column.path,
            :type => column.type,
            :flags => column.flags,
            :domain => column.domain,
            :range => column.range,
            :source => column.source,
          }
        }
      )
    end
  end
end
