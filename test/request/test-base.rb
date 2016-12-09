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

class TestRequestBase < Test::Unit::TestCase
  sub_test_case "#extend" do
    setup do
      @request = Groonga::Client::Request::Base.new("status")
    end

    test "Module" do
      assert do
        not @request.respond_to?(:new_method)
      end
      extension = Module.new do
        def new_method
        end
      end
      extended_request = @request.extend(extension)
      assert do
        extended_request.respond_to?(:new_method)
      end
    end

    test "block" do
      assert do
        not @request.respond_to?(:new_method)
      end
      extended_request = @request.extend do
        def new_method
        end
      end
      assert do
        extended_request.respond_to?(:new_method)
      end
    end
  end
end
