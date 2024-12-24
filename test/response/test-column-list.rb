# Copyright (C) 2013  Kosuke Asami
# Copyright (C) 2017-2024  Sutou Kouhei <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require "response/helper"

class TestResponseColumnList < Test::Unit::TestCase
  class TestParse < self
    include TestResponseHelper

    def column(attributes)
      c = Groonga::Client::Response::ColumnList::Column.new
      attributes.each do |name, value|
        c[name] = value
      end
      c
    end

    def test_parse
      header = [0, 1372430096.70991, 0.000522851943969727]
      body = [
        [
          ["id", "UInt32"],
          ["name", "ShortText"],
          ["path", "ShortText"],
          ["type", "ShortText"],
          ["flags", "ShortText"],
          ["domain", "ShortText"],
          ["range", "ShortText"],
          ["source", "ShortText"],
          ["generator", "ShortText"],
        ],
        [
          256,
          "content",
          "/tmp/test.db.0000100",
          "var",
          "COLUMN_SCALAR|PERSISTENT",
          "TestTable",
          "ShortText",
          [],
          "html_untag(html_content)",
        ],
      ]
      raw_response = [header, body].to_json

      response = parse_raw_response("column_list", raw_response)
      assert_equal([
                     column(:id => 256,
                            :name => "content",
                            :path => "/tmp/test.db.0000100",
                            :type => "var",
                            :flags => "COLUMN_SCALAR|PERSISTENT",
                            :domain => "TestTable",
                            :range => "ShortText",
                            :source => [],
                            :generator => "html_untag(html_content)"),
                   ],
                   response.to_a)
    end

    def test_parse_before_14_1_0
      header = [0, 1372430096.70991, 0.000522851943969727]
      body = [
        [
          ["id", "UInt32"],
          ["name", "ShortText"],
          ["path", "ShortText"],
          ["type", "ShortText"],
          ["flags", "ShortText"],
          ["domain", "ShortText"],
          ["range", "ShortText"],
          ["source", "ShortText"],
        ],
        [
          256,
          "content",
          "/tmp/test.db.0000100",
          "var",
          "COLUMN_SCALAR|PERSISTENT",
          "TestTable",
          "ShortText",
          [],
        ],
      ]
      raw_response = [header, body].to_json

      response = parse_raw_response("column_list", raw_response)
      assert_equal([
                     column(:id => 256,
                            :name => "content",
                            :path => "/tmp/test.db.0000100",
                            :type => "var",
                            :flags => "COLUMN_SCALAR|PERSISTENT",
                            :domain => "TestTable",
                            :range => "ShortText",
                            :source => []),
                   ],
                   response.to_a)
    end
  end

  class TestBody < self
    def setup
      @command = Groonga::Command::Base.new("column_list", "table" => "Memos")
    end

    def create_response(columns)
      header = [0, 1372430096.70991, 0.000522851943969727]
      body = [
        [
          ["id", "UInt32"],
          ["name", "ShortText"],
          ["path", "ShortText"],
          ["type", "ShortText"],
          ["flags", "ShortText"],
          ["domain", "ShortText"],
          ["range", "ShortText"],
          ["source", "ShortText"],
        ],
        *columns,
      ]
      Groonga::Client::Response::ColumnList.new(@command, header, body)
    end

    class TestFullName < self
      def create_response(domain, name)
        columns = [
          [
            256,
            name,
            "/tmp/test.db.0000100",
            "var",
            "COLUMN_SCALAR|PERSISTENT",
            domain,
            "ShortText",
            [],
          ]
        ]
        super(columns)
      end

      def test_full_name
        response = create_response("Memos", "content")
        assert_equal("Memos.content",
                     response[0].full_name)
      end
    end

    class TestFlags < self
      def create_response(flags)
        columns = [
          [
            256,
            "content",
            "/tmp/test.db.0000100",
            "var",
            flags,
            "Memos",
            "ShortText",
            [],
          ]
        ]
        super(columns)
      end

      def test_multiple
        response = create_response("COLUMN_SCALAR|PERSISTENT")
        assert_equal(["COLUMN_SCALAR", "PERSISTENT"],
                     response[0].flags)
      end

      def test_scalar?
        response = create_response("COLUMN_SCALAR|PERSISTENT")
        assert do
          response[0].scalar?
        end
      end

      def test_vector?
        response = create_response("COLUMN_VECTOR|PERSISTENT")
        assert do
          response[0].vector?
        end
      end

      def test_index?
        response = create_response("COLUMN_INDEX|WITH_POSITION|PERSISTENT")
        assert do
          response[0].index?
        end
      end
    end

    class TestSource < self
      def create_response(sources)
        columns = [
          [
            256,
            "content",
            "/tmp/test.db.0000100",
            "var",
            "COLUMN_INDEX|WITH_POSITION|PERSISTENT",
            "Memos",
            "ShortText",
            sources,
          ]
        ]
        super(columns)
      end

      def test_source
        sources = ["Memos.title", "Memos.content"]
        response = create_response(sources)
        assert_equal(sources, response[0].source)
      end

      def test_sources
        sources = ["Memos.title", "Memos.content"]
        response = create_response(sources)
        assert_equal(sources, response[0].sources)
      end
    end
  end
end

