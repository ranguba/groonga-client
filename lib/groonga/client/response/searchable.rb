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

module Groonga
  class Client
    module Response
      module Searchable
        include Enumerable

        attr_accessor :records
        attr_accessor :raw_columns
        attr_accessor :raw_records

        # For Kaminari
        def limit_value
          (@command[:limit] || 10).to_i
        end

        # For Kaminari
        def offset_value
          (@command[:offset] || 0).to_i
        end

        # For Kaminari
        def size
          records.size
        end

        def each(&block)
          records.each(&block)
        end

        private
        def parse_records(raw_columns, raw_records)
          column_names = {}
          columns = raw_columns.collect do |column|
            if column.is_a?(::Array)
              name, type = column
            else
              name = column["name"]
              type = column["type"]
            end
            base_column_name = name
            suffix = 2
            while column_names.key?(name)
              name = "#{base_column_name}#{suffix}"
              suffix += 1
            end
            column_names[name] = true
            [name, type]
          end

          (raw_records || []).collect do |raw_record|
            record = Record.new
            columns.each_with_index do |(name, type), i|
              record[name] = convert_value(raw_record[i], type)
            end
            record
          end
        end

        def convert_value(value, type)
          case value
          when ::Array
            value.collect do |element|
              convert_value(element, type)
            end
          else
            case type
            when "Time"
              Time.at(value)
            else
              value
            end
          end
        end

        class Record < ::Hash
          include Hashie::Extensions::MethodAccess
        end
      end
    end
  end
end
