# Copyright (C) 2014  Kouhei Sutou <kou@clear-code.com>
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
    class TestStatusCode < self
      def test_have_header
        header = [
          -21,
          1396012478.14975,
          0.00050806999206543,
        ]
        response = Groonga::Client::Response::Base.new(nil, header, nil)
        assert_equal(-21, response.status_code)
      end

      def test_no_header
        response = Groonga::Client::Response::Error.new(nil, nil, nil)
        assert_equal(0, response.status_code)
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
end
