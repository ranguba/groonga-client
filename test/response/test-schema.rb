# Copyright (C) 2016  Kouhei Sutou <kou@clear-code.com>
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

class TestResponseSchema < Test::Unit::TestCase
  class TestParseRawResponse < self
    include TestResponseHelper

    def test_select
      header = [0, 1372430096.70991, 0.000522851943969727]
      body = {}
      raw_response = [header, body].to_json

      response = parse_raw_response("schema", raw_response)
      assert_equal(Groonga::Client::Response::Schema, response.class)
    end
  end

  class TestBody < self
    def setup
      @command = Groonga::Command::Base.new("schema", {})
    end

    def create_response(body)
      header = [0, 1372430096.70991, 0.000522851943969727]
      Groonga::Client::Response::Schema.new(@command, header, body)
    end

    class TestTables < self
      def test_key_type
        body = {
          "types" => {
            "ShortText" => {
              "name" => "ShortText",
            },
          },
          "tables" => {
            "Users" => {
              "key_type" => {
                "name" => "ShortText",
                "type" => "type",
              },
            }
          }
        }
        response = create_response(body)
        assert_equal("ShortText",
                     response.tables["Users"].key_type.name)
      end

      def test_normalizer
        body = {
          "normalizers" => {
            "NormalizerAuto" => {
              "name" => "NormalizerAuto",
            },
          },
          "tables" => {
            "Users" => {
              "normalizer" => {
                "name" => "NormalizerAuto",
              },
            }
          }
        }
        response = create_response(body)
        assert_equal(response.normalizers["NormalizerAuto"],
                     response.tables["Users"].normalizer)
      end

      def test_columns
        body = {
          "tables" => {
            "Users" => {
              "columns" => {
                "age" => {
                  "name" => "age",
                }
              }
            }
          }
        }
        response = create_response(body)
        assert_equal("age",
                     response.tables["Users"].columns["age"].name)
      end

      def test_indexes
        body = {
          "tables" => {
            "Users" => {
              "indexes" => [
                {
                  "full_name" => "Names.users"
                }
              ]
            }
          }
        }
        response = create_response(body)
        assert_equal("Names.users",
                     response.tables["Users"].indexes[0].full_name)
      end
    end

    class TestColumn < self
      def test_indexes
        body = {
          "tables" => {
            "Users" => {
              "columns" => {
                "age" => {
                  "indexes" => [
                    {
                      "full_name" => "Ages.users",
                    }
                  ]
                }
              }
            }
          }
        }
        response = create_response(body)
        assert_equal("Ages.users",
                     response.tables["Users"].columns["age"].indexes[0].full_name)
      end
    end

    class TestIndex < self
      def test_table
        body = {
          "tables" => {
            "Names" => {
              "name" => "Names",
            },
            "Users" => {
              "indexes" => [
                {
                  "table" => "Names"
                }
              ]
            }
          }
        }
        response = create_response(body)
        assert_equal(response.tables["Names"],
                     response.tables["Users"].indexes[0].table)
      end

      def test_column
        body = {
          "tables" => {
            "Names" => {
              "name" => "Names",
              "columns" => {
                "users_key" => {
                  "name" => "users_key",
                },
              },
            },
            "Users" => {
              "indexes" => [
                {
                  "table" => "Names",
                  "name" => "users_key",
                }
              ]
            }
          }
        }
        response = create_response(body)
        assert_equal(response.tables["Names"].columns["users_key"],
                     response.tables["Users"].indexes[0].column)
      end
    end
  end
end
