# Copyright (C) 2017  Kouhei Sutou <kou@clear-code.com>
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

class TestRequestMerger < Test::Unit::TestCase
  sub_test_case "OverwriteMerger" do
    def merge(parameters1, parameters2)
      klass = Groonga::Client::Request::OverwriteMerger
      klass.new(parameters1, parameters2).to_parameters
    end

    def param(name, value)
      Groonga::Client::Request::RequestParameter.new(name, value)
    end

    test "(nil, nil)" do
      assert_equal({}, merge(nil, nil))
    end

    test "(nil, parameter)" do
      assert_equal({"name" => "value"},
                   merge(nil, param("name", "value")))
    end

    test "(parameter, nil)" do
      assert_equal({"name" => "value"},
                   merge(param("name", "value"), nil))
    end

    test "(parameter, parameter)" do
      assert_equal({"name" => "value2"},
                   merge(param("name", "value1"),
                         param("name", "value2")))
    end
  end
end
