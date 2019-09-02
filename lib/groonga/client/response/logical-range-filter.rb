# Copyright (C) 2019  Sutou Kouhei <kou@clear-code.com>
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

require "groonga/client/response/base"
require "groonga/client/response/searchable"

module Groonga
  class Client
    module Response
      class LogicalRangeFilter < Base
        Response.register("logical_range_filter", self)

        include Searchable

        attr_accessor :records

        def body=(body)
          super(body)
          parse_body(body)
        end

        private
        def parse_body(body)
          if body.is_a?(::Array)
            @raw_columns, *@raw_records = body.first
            @raw_records ||= []
            @records = parse_records(raw_columns, raw_records)
          else
            @raw_columns = body["columns"]
            @raw_records = body["records"] || []
          end
          @records = parse_records(@raw_columns, @raw_records)
          body
        end
      end
    end
  end
end

