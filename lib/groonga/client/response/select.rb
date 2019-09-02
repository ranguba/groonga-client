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
require "groonga/client/response/drilldownable"
require "groonga/client/response/searchable"

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

        include Drilldownable
        include Searchable

        # @return [Integer] The number of records that match againt
        #   a search condition.
        attr_accessor :n_hits
        # For Kaminari
        alias_method :total_count, :n_hits

        # @return [::Hash<String, Groonga::Client::Response::Select::Slice>]
        #
        # @since 0.3.4
        attr_accessor :slices

        def body=(body)
          super(body)
          parse_body(body)
        end

        private
        def parse_body(body)
          if body.is_a?(::Array)
            @n_hits, @raw_columns, @raw_records, @records =
              parse_record_set_v1(body.first)
            if @command.slices.empty?
              raw_slices = nil
              raw_drilldowns = body[1..-1]
            else
              raw_slices, *raw_drilldowns = body[1..-1]
            end
            @slices = parse_slices_v1(raw_slices)
            drilldown_keys = @command.drilldowns
            labeled_drilldowns = @command.labeled_drilldowns
            if drilldown_keys.empty? and !labeled_drilldowns.empty?
              @drilldowns = parse_labeled_drilldowns(labeled_drilldowns,
                                                     raw_drilldowns[0])
            else
              @drilldowns = parse_drilldowns(drilldown_keys, raw_drilldowns)
            end
          else
            @n_hits, @raw_columns, @raw_records, @records =
              parse_record_set_v3(body)
            drilldown_keys = @command.drilldowns
            labeled_drilldowns = @command.labeled_drilldowns
            if labeled_drilldowns.empty?
              drilldown_keys.each do |key|
                labeled_drilldown =
                  Groonga::Command::Drilldownable::Drilldown.new
                labeled_drilldown.label = key
                labeled_drilldown.keys = [key]
                labeled_drilldowns[key] = labeled_drilldown
              end
            end
            @drilldowns = parse_labeled_drilldowns(labeled_drilldowns,
                                                   body["drilldowns"])
            @slices = parse_slices_v3(body["slices"])
          end
          body
        end

        def parse_record_set_v1(raw_record_set)
          n_hits = raw_record_set.first.first
          raw_columns = raw_record_set[1]
          raw_records = raw_record_set[2..-1] || []
          [
            n_hits,
            raw_columns,
            raw_records,
            parse_records(raw_columns, raw_records),
          ]
        end

        def parse_record_set_v3(raw_record_set)
          n_hits = raw_record_set["n_hits"]
          raw_columns = raw_record_set["columns"]
          raw_records = raw_record_set["records"] || []
          [
            n_hits,
            raw_columns,
            raw_records,
            parse_records(raw_columns, raw_records),
          ]
        end

        def parse_slices_v1(raw_slices)
          slices = {}
          (raw_slices || {}).each do |key, raw_slice|
            requested_slice = @command.slices[key]
            if raw_slice.last.is_a?(::Hash)
              raw_drilldowns = raw_slice.last
              raw_slice = raw_slice[0..-2]
              drilldowns =
                parse_labeled_drilldowns(requested_slice.labeled_drilldowns,
                                         raw_drilldowns)
            else
              drilldowns = {}
            end
            n_hits, _, _, records = parse_record_set_v1(raw_slice)
            slices[key] = Slice.new(key, n_hits, records, drilldowns)
          end
          slices
        end

        def parse_slices_v3(raw_slices)
          slices = {}
          (raw_slices || {}).each do |key, raw_slice|
            requested_slice = @command.slices[key]
            n_hits, _, _, records = parse_record_set_v3(raw_slice)
              drilldowns =
                parse_labeled_drilldowns(requested_slice.labeled_drilldowns,
                                         raw_slice["drilldowns"])
            slices[key] = Slice.new(key, n_hits, records, drilldowns)
          end
          slices
        end

        class Slice < Struct.new(:key, :n_hits, :records, :drilldowns)
        end
      end
    end
  end
end

