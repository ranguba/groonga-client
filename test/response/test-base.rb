# Copyright (C) 2014-2018  Kouhei Sutou <kou@clear-code.com>
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

class TestResponseBase < Test::Unit::TestCase
  class TestHeader < self
    class TestCommandVersion1 < self
      class TestReturnCode < self
        def test_have_header
          header = [
            -21,
            1396012478.14975,
            0.00050806999206543,
          ]
          response = Groonga::Client::Response::Base.new(nil, header, nil)
          assert_equal(-21, response.return_code)
        end

        def test_no_header
          response = Groonga::Client::Response::Error.new(nil, nil, nil)
          assert_equal(0, response.return_code)
        end
      end

      class TestStartTime < self
        def test_have_header
          start_time = 1396012478.14975
          header = [
            -21,
            start_time,
            0.00050806999206543,
          ]
          response = Groonga::Client::Response::Base.new(nil, header, nil)
          assert_equal(Time.at(start_time), response.start_time)
        end

        def test_no_header
          response = Groonga::Client::Response::Error.new(nil, nil, nil)
          assert_equal(Time.at(0), response.start_time)
        end
      end

      class TestElapsedTime < self
        def test_have_header
          elapsed_time = 0.00050806999206543
          header = [
            -21,
            1396012478.14975,
            elapsed_time,
          ]
          response = Groonga::Client::Response::Base.new(nil, header, nil)
          assert_equal(elapsed_time, response.elapsed_time)
        end

        def test_no_header
          response = Groonga::Client::Response::Error.new(nil, nil, nil)
          assert_equal(0.0, response.elapsed_time)
        end
      end

      class TestErrorMessage < self
        def test_have_header
          error_message = "invalid argument"
          header = [
            -21,
            1396012478.14975,
            0.00050806999206543,
            error_message,
          ]
          response = Groonga::Client::Response::Base.new(nil, header, nil)
          assert_equal(error_message, response.error_message)
        end

        def test_no_header
          response = Groonga::Client::Response::Error.new(nil, nil, nil)
          assert_nil(response.error_message)
        end
      end

      class TestSuccess < self
        def test_have_header
          header = [
            -21,
            1396012478.14975,
            0.00050806999206543,
          ]
          response = Groonga::Client::Response::Base.new(nil, header, nil)
          assert do
            not response.success?
          end
        end

        def test_no_header
          response = Groonga::Client::Response::Error.new(nil, nil, nil)
          assert do
            response.success?
          end
        end
      end
    end

    class TestCommandVersion3 < self
      class TestReturnCode < self
        def test_have_header
          header = {
            "return_code"  => -21,
            "start_time"   => 1396012478.14975,
            "elapsed_time" => 0.00050806999206543,
          }
          response = Groonga::Client::Response::Base.new(nil, header, nil)
          assert_equal(-21, response.return_code)
        end

        def test_no_header
          response = Groonga::Client::Response::Error.new(nil, nil, nil)
          assert_equal(0, response.return_code)
        end
      end

      class TestStartTime < self
        def test_have_header
          start_time = 1396012478.14975
          header = {
            "return_code"  => -21,
            "start_time"   => start_time,
            "elapsed_time" => 0.00050806999206543,
          }
          response = Groonga::Client::Response::Base.new(nil, header, nil)
          assert_equal(Time.at(start_time), response.start_time)
        end

        def test_no_header
          response = Groonga::Client::Response::Error.new(nil, nil, nil)
          assert_equal(Time.at(0), response.start_time)
        end
      end

      class TestElapsedTime < self
        def test_have_header
          elapsed_time = 0.00050806999206543
          header = {
            "return_code"  => -21,
            "start_time"   => 1396012478.14975,
            "elapsed_time" => elapsed_time,
          }
          response = Groonga::Client::Response::Base.new(nil, header, nil)
          assert_equal(elapsed_time, response.elapsed_time)
        end

        def test_no_header
          response = Groonga::Client::Response::Error.new(nil, nil, nil)
          assert_equal(0.0, response.elapsed_time)
        end
      end

      class TestErrorMessage < self
        def test_have_header
          error_message = "invalid argument"
          header = {
            "return_code"  => -21,
            "start_time"   => 1396012478.14975,
            "elapsed_time" => 0.00050806999206543,
            "error" => {
              "message" => error_message,
            },
          }
          response = Groonga::Client::Response::Base.new(nil, header, nil)
          assert_equal(error_message, response.error_message)
        end

        def test_no_header
          response = Groonga::Client::Response::Error.new(nil, nil, nil)
          assert_nil(response.error_message)
        end
      end

      class TestSuccess < self
        def test_have_header
          header = {
            "return_code"  => -21,
            "start_time"   => 1396012478.14975,
            "elapsed_time" => 0.00050806999206543,
          }
          response = Groonga::Client::Response::Base.new(nil, header, nil)
          assert do
            not response.success?
          end
        end

        def test_no_header
          response = Groonga::Client::Response::Error.new(nil, nil, nil)
          assert do
            response.success?
          end
        end
      end
    end
  end

  class TestParse < self
    def test_jsonp
      command = Groonga::Command::Base.new("status", {"callback" => "a"})
      response = [
        [0, 1396012478, 0.00050806999206543],
        {"start_time" => 1396012478},
      ]
      raw_response = "a(#{response.to_json});"
      response = Groonga::Client::Response::Base.parse(command, raw_response)
      assert_equal(1396012478, response.body["start_time"])
    end

    def test_invalid_json
      command = Groonga::Command::Base.new("cancel")
      raw_response = '["header", :{"return_code":-77}}'
      begin
        JSON.parse(raw_response)
      rescue JSON::ParserError => error
        parse_error_message = "invalid JSON: #{error}"
      end
      error = Groonga::Client::InvalidResponse.new(command, raw_response, parse_error_message)

      assert_raise(error) do
        Groonga::Client::Response::Base.parse(command, raw_response)
      end
    end
  end
end
