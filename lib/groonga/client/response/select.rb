require "groonga/client/response/base"

module Groonga
  class Client
    module Response
      class Select < Base
        Response.register("select", self)

        attr_accessor :records, :total_records
        attr_accessor :drilldowns, :total_drilldowns

        def initialize(header, body)
          super(header, parse_body(body))
        end

        private
        def parse_body(body)
          @total_records, @records = parse_match_items(body.first)
          @total_drilldowns, @drilldowns = parse_match_items(body.last)
          body
        end

        def parse_match_items(match_items)
          total_records = match_items.first.first
          properties = match_items[1]
          infos = match_items[2..-1]
          records = infos.collect do |info|
            record = {}
            properties.each_with_index do |(name, _), i|
              record[name] = info[i]
            end
            record
          end if infos
          [total_records, records]
        end

        def parse_drilldowns(drilldowns)
          total_drilldowns = drilldowns.first.first
          properties = drilldowns[1]
          infos = drilldowns[2..-1]
          records = infos.collect do |info|
            record = {}
            properties.each_with_index do |(name, _), i|
              record[name] = info[i]
            end
            record
          end if infos
          [total_drilldowns, records]
        end
      end
    end
  end
end

