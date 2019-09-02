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
      module Drilldownable
        # @return [::Array<Groonga::Client::Response::Select::Drilldown>,
        #          ::Hash<String, Groonga::Client::Response::Select::Drilldown>]
        #   If labeled drilldowns are used or command version 3 or
        #   later is used, `{"label1" => drilldown1, "label2" => drilldown2}`
        #   is returned since 0.3.1.
        #
        #   Otherwise, `[drilldown1, drilldown2]` is returned.
        attr_accessor :drilldowns

        private
        def parse_drilldown(label, keys, raw_drilldown)
          if raw_drilldown.is_a?(::Array)
            n_hits = raw_drilldown[0][0]
            raw_columns = raw_drilldown[1]
            raw_records = raw_drilldown[2..-1]
          else
            n_hits = raw_drilldown["n_hits"]
            raw_columns = raw_drilldown["columns"]
            raw_records = raw_drilldown["records"]
          end
          records = parse_records(raw_columns, raw_records)
          Drilldown.new(label,
                        keys,
                        n_hits,
                        records,
                        raw_columns,
                        raw_records)
        end

        def parse_drilldowns(keys, raw_drilldowns)
          (raw_drilldowns || []).collect.with_index do |raw_drilldown, i|
            key = keys[i]
            parse_drilldown(key, [key], raw_drilldown)
          end
        end

        def parse_labeled_drilldowns(labeled_drilldown_requests,
                                     raw_drilldowns)
          drilldowns = {}
          (raw_drilldowns || {}).each do |label, raw_drilldown|
            labeled_drilldown_request = labeled_drilldown_requests[label]
            drilldowns[label] = parse_drilldown(label,
                                                labeled_drilldown_request.keys,
                                                raw_drilldown)
          end
          drilldowns
        end

        class Drilldown < Struct.new(:label,
                                     :keys,
                                     :n_hits,
                                     :records,
                                     :raw_columns,
                                     :raw_records)
          # @deprecated since 0.2.6. Use {#records} instead.
          alias_method :items, :records

          def key
            keys.join(", ")
          end
        end
      end
    end
  end
end
