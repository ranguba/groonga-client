# Copyright (C) 2013-2015  Kouhei Sutou <kou@clear-code.com>
# Copyright (C) 2013  Kosuke Asami
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

module Groonga
  class Client
    module Response
      class Select < Base
        Response.register("select", self)

        # @return [Integer] The number of records that match againt
        #   a search condition.
        attr_accessor :n_hits
        attr_accessor :records
        attr_accessor :drilldowns

        def body=(body)
          super(body)
          parse_body(body)
        end

        private
        def parse_body(body)
          if body.is_a?(::Array)
            @n_hits, @records = parse_match_records_v1(body.first)
            @drilldowns = parse_drilldowns_v1(body[1..-1])
          else
            @n_hits, @records = parse_match_records_v3(body)
            @drilldowns = parse_drilldowns_v3(body["drilldowns"])
          end
          body
        end

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
            record = {}
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

        def parse_match_records_v1(raw_records)
          [
            raw_records.first.first,
            parse_records(raw_records[1], raw_records[2..-1]),
          ]
        end

        def parse_match_records_v3(raw_records)
          [
            raw_records["n_hits"],
            parse_records(raw_records["columns"], raw_records["records"]),
          ]
        end

        def parse_drilldowns_v1(raw_drilldowns)
          (raw_drilldowns || []).collect.with_index do |raw_drilldown, i|
            key = @command.drilldowns[i]
            n_hits, records = parse_match_records_v1(raw_drilldown)
            Drilldown.new(key, n_hits, records)
          end
        end

        def parse_drilldowns_v3(raw_drilldowns)
          (raw_drilldowns || {}).collect do |(key, raw_drilldown)|
            n_hits, records = parse_match_records_v3(raw_drilldown)
            Drilldown.new(key, n_hits, records)
          end
        end

        class Drilldown < Struct.new(:key, :n_hits, :records)
          # @deprecated since 0.2.6. Use {#records} instead.
          alias_method :items, :records
        end
      end
    end
  end
end

