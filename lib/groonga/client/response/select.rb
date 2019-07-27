# Copyright (C) 2013-2019  Sutou Kouhei <kou@clear-code.com>
# Copyright (C) 2013  Kosuke Asami
# Copyright (C) 2016  Masafumi Yokoyama <yokoyama@clear-code.com>
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

        class << self
          private
          def parse_xml(response)
            document = REXML::Document.new(response)
            return super if document.root.name == "RESULT"

            result_page = document.elements["SEGMENTS/SEGMENT/RESULTPAGE"]
            result_set = result_page.elements["RESULTSET"]
            n_hits, columns, records = parse_xml_result_set(result_set)

            navigation_entry = result_page.elements["NAVIGATIONENTRY"]
            drilldowns = parse_xml_navigation_entry(navigation_entry)

            header = nil
            body = [
              [
                [n_hits],
                columns,
                *records,
              ],
              *drilldowns,
            ]
            [header, body]
          end

          def parse_xml_result_set(result_set)
            n_hits = Integer(result_set.attributes["NHITS"])

            columns = []
            records = []
            result_set.each_element("HIT") do |hit|
              if columns.empty?
                hit.each_element("FIELD") do |field|
                  name = field.attributes["NAME"]
                  columns << [name, "ShortText"]
                end
              end
              record = []
              hit.each_element("FIELD") do |field|
                record << field.text
              end
              records << record
            end

            [n_hits, columns, records]
          end

          def parse_xml_navigation_entry(navigation_entry)
            return [] if navigation_entry.nil?

            drilldowns = []
            navigation_entry.each_element("NAVIGATIONELEMENTS") do |elements|
              n_hits = Integer(elements.attributes["COUNT"])
              columns = []
              drilldown = []
              elements.each_element("NAVIGATIONELEMENT") do |element|
                if columns.empty?
                  element.attributes.each do |name, value|
                    columns << [name, "ShortText"]
                  end
                end

                drilldown << element.attributes.collect do |_, value|
                  value
                end
              end

              drilldowns << [
                [n_hits],
                columns,
                *drilldown,
              ]
            end

            drilldowns
          end

          def parse_tsv_body(tsv)
            record_sets = []

            n_hits = parse_tsv_n_hits(tsv.shift)
            columns = parse_tsv_columns(tsv.shift)
            records = []
            loop do
              row = tsv.shift
              break if row.size == 1 and row[0] == "END"
              if (row.size % 4).zero? and row[0] == "[" and row[-1] == "]"
                next_n_hits_row = records.pop
                record_sets << [
                  [n_hits],
                  columns,
                  *records,
                ]
                n_hits = parse_tsv_n_hits(next_n_hits_row)
                columns = parse_tsv_columns(row)
                records = []
                next
              end
              records << parse_tsv_record(row)
            end

            record_sets << [
              [n_hits],
              columns,
              *records,
            ]
            record_sets
          end

          def parse_tsv_n_hits(row)
            Integer(row[0], 10)
          end

          def parse_tsv_columns(row)
            columns = []
            column = nil
            row.each do |value|
              case value
              when "["
                column = []
              when "]"
                columns << column
              else
                column << value
              end
            end
            columns
          end

          def parse_tsv_record(row)
            record = []
            column_value = nil
            row.each do |value|
              case value
              when "["
                column_value = []
              when "]"
                record << column_value
              else
                if column_value
                  column_value << value
                else
                  record << value
                end
              end
            end
            record
          end
        end

        include Enumerable

        # @return [Integer] The number of records that match againt
        #   a search condition.
        attr_accessor :n_hits
        # For Kaminari
        alias_method :total_count, :n_hits
        attr_accessor :records

        # @return [::Array<Groonga::Client::Response::Select::Drilldown>,
        #          ::Hash<String, Groonga::Client::Response::Select::Drilldown>]
        #   If labeled drilldowns are used or command version 3 or
        #   later is used, `{"label1" => drilldown1, "label2" => drilldown2}`
        #   is returned since 0.3.1.
        #
        #   Otherwise, `[drilldown1, drilldown2]` is returned.
        attr_accessor :drilldowns

        # @return [::Hash<String, Groonga::Client::Response::Select::Slice>]
        #
        # @since 0.3.4
        attr_accessor :slices

        def body=(body)
          super(body)
          parse_body(body)
        end

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
        def parse_body(body)
          if body.is_a?(::Array)
            @n_hits, @records = parse_match_records_v1(body.first)
            if @command.slices.empty?
              raw_slices = nil
              raw_drilldowns = body[1..-1]
            else
              raw_slices, *raw_drilldowns = body[1..-1]
            end
            @slices = parse_slices_v1(raw_slices)
            @drilldowns = parse_drilldowns_v1(raw_drilldowns)
          else
            @n_hits, @records = parse_match_records_v3(body)
            @drilldowns = parse_drilldowns_v3(body["drilldowns"])
            @slices = parse_slices_v3(body["slices"])
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
          request_drilldowns = @command.drilldowns
          if request_drilldowns.empty? and !@command.labeled_drilldowns.empty?
            drilldowns = {}
            (raw_drilldowns[0] || {}).each do |label, raw_drilldown|
              n_hits, records = parse_match_records_v1(raw_drilldown)
              drilldowns[label] = Drilldown.new(label, n_hits, records)
            end
            drilldowns
          else
            (raw_drilldowns || []).collect.with_index do |raw_drilldown, i|
              key = request_drilldowns[i]
              n_hits, records = parse_match_records_v1(raw_drilldown)
              Drilldown.new(key, n_hits, records)
            end
          end
        end

        def parse_drilldowns_v3(raw_drilldowns)
          drilldowns = {}
          (raw_drilldowns || {}).each do |key, raw_drilldown|
            n_hits, records = parse_match_records_v3(raw_drilldown)
            drilldowns[key] = Drilldown.new(key, n_hits, records)
          end
          drilldowns
        end

        def parse_slices_v1(raw_slices)
          slices = {}
          (raw_slices || {}).each do |key, raw_slice|
            if raw_slice.last.is_a?(::Hash)
              raw_drilldowns = raw_slice.last
              raw_slice = raw_slice[0..-2]
              drilldowns = {}
              raw_drilldowns.each do |label, raw_drilldown|
                n_hits, records = parse_match_records_v1(raw_drilldown)
                drilldowns[label] = Drilldown.new(label, n_hits, records)
              end
            else
              drilldowns = {}
            end
            n_hits, records = parse_match_records_v1(raw_slice)
            slices[key] = Slice.new(key, n_hits, records, drilldowns)
          end
          slices
        end

        def parse_slices_v3(raw_slices)
          slices = {}
          (raw_slices || {}).each do |key, raw_slice|
            n_hits, records = parse_match_records_v3(raw_slice)
            drilldowns = parse_drilldowns_v3(raw_slice["drilldowns"])
            slices[key] = Slice.new(key, n_hits, records, drilldowns)
          end
          slices
        end

        class Record < ::Hash
          include Hashie::Extensions::MethodAccess
        end

        class Drilldown < Struct.new(:key, :n_hits, :records)
          # @deprecated since 0.2.6. Use {#records} instead.
          alias_method :items, :records
        end

        class Slice < Struct.new(:key, :n_hits, :records, :drilldowns)
        end
      end
    end
  end
end

