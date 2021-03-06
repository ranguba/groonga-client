# Copyright (C) 2016-2017  Kouhei Sutou <kou@clear-code.com>
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

class TestResponseLoad < Test::Unit::TestCase
  private
  def create_response(command, body)
    header = {
      "return_code"  => 0,
      "start_time"   => 1372430096.70991,
      "elapsed_time" => 0.000522851943969727,
    }
    Groonga::Client::Response::Load.new(command, header, body)
  end

  sub_test_case("#n_loaded_records") do
    test("command_version=1") do
      command = Groonga::Command::Load.new("load",
                                           {"command_version" => "1"})
      response = create_response(command, 29)
      assert_equal(29, response.n_loaded_records)
    end

    test("command_version=3") do
      command = Groonga::Command::Load.new("load",
                                           {"command_version" => "3"})
      response = create_response(command, {"n_loaded_records" => 29})
      assert_equal(29, response.n_loaded_records)
    end
  end

  sub_test_case("#loaded_ids") do
    test("command_version=1") do
      command = Groonga::Command::Load.new("load",
                                           {"command_version" => "1"})
      response = create_response(command, 29)
      assert_equal([], response.loaded_ids)
    end

    sub_test_case("command_version=3") do
      test("no output_*") do
        command = Groonga::Command::Load.new("load",
                                             {"command_version" => "3"})
        response = create_response(command, {"n_loaded_records" => 29})
        assert_equal(29, response.n_loaded_records)
      end

      test("output_ids=yes") do
        command = Groonga::Command::Load.new("load",
                                             {
                                               "command_version" => "3",
                                               "output_ids" => "yes",
                                             })
        loaded_ids = [1, 2, 0, 4, 3]
        response = create_response(command,
                                   {
                                     "n_loaded_records" => 4,
                                     "loaded_ids" => loaded_ids,
                                   })
        assert_equal(loaded_ids, response.loaded_ids)
      end

      test("output_errors=yes") do
        command = Groonga::Command::Load.new("load",
                                             {
                                               "command_version" => "3",
                                               "output_errors" => "yes",
                                             })
        raw_errors = [
          {
            "return_code" => 0,
            "message" => nil,
          },
          {
            "return_code" => -22,
            "message" => "invalid argument",
          },
          {
            "return_code" => 0,
            "message" => nil,
          },
        ]
        errors = [
          Groonga::Client::Response::Load::Error.new(0, nil),
          Groonga::Client::Response::Load::Error.new(-22, "invalid argument"),
          Groonga::Client::Response::Load::Error.new(0, nil),
        ]
        response = create_response(command,
                                   {
                                     "n_loaded_records" => 3,
                                     "errors" => raw_errors,
                                   })
        assert_equal(errors, response.errors)
      end
    end
  end
end
