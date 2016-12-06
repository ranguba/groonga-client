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

  sub_test_case("#ids") do
    test("command_version=1") do
      command = Groonga::Command::Load.new("load",
                                           {"command_version" => "1"})
      response = create_response(command, 29)
      assert_equal([], response.ids)
    end

    sub_test_case("command_version=3") do
      test("no output_ids") do
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
        ids = [1, 2, 0, 4, 3]
        response = create_response(command,
                                   {
                                     "n_loaded_records" => 4,
                                     "ids" => ids,
                                   })
        assert_equal(ids, response.ids)
      end
    end
  end
end
