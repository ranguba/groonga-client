require "groonga/client/response/base"

module Groonga
  class Client
    module Response
      class Select < Base
        Response.register("select", self)

        attr_accessor :records, :n_records
        attr_accessor :drilldowns

        def initialize(header, body)
          super(header, parse_body(body))
        end

        private
        def parse_body(body)
          @n_records, @records = parse_match_records(body.first)
          @drilldowns = parse_drilldowns(body[1..-1])
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
          raw_drilldowns.collect do |raw_drilldown|
            n_hits, items = parse_result(raw_drilldown)
            Drilldown.new(n_hits, items)
          end if raw_drilldowns
        end

        Drilldown = Struct.new(:n_hits, :items)
      end
    end
  end
end

