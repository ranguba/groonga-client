require "groonga/client/response/base"

module Groonga
  class Client
    module Response
      class Select < Base
        Response.register("select", self)

        attr_accessor :records, :n_records
        attr_accessor :drilldowns, :n_drilldowns

        def initialize(header, body)
          super(header, parse_body(body))
        end

        private
        def parse_body(body)
          @n_records, @records = parse_match_records(body.first)
          @n_drilldowns, @drilldowns = parse_drilldowns(body.last)
          body
        end

        def parse_result(raw_result)
          total_items = raw_result.first.first
          properties = raw_result[1]
          infos = raw_result[2..-1]
          items = infos.collect do |info|
            item = {}
            properties.each_with_index do |(name, _), i|
              item[name] = info[i]
            end
            item
          end if infos
          [total_items, items]
        end

        def parse_match_records(raw_records)
          parse_result(raw_records)
        end

        def parse_drilldowns(raw_drilldowns)
          parse_result(raw_drilldowns)
        end
      end
    end
  end
end

