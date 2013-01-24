# -*- coding: utf-8 -*-
#
# Copyright (C) 2013  Haruka Yoshihara <yoshihara@clear-code.com>
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
      class TableList < Base
        Response.register("table_list", self)

        def initialize(json_text)
          if json_text.nil?
            @header = nil
            @body = nil
          else
            @header, table_infos = create_formatted_response(json_text)
            @body = table_infos.collect do |table_info|
              TableInfo.new(table_info)
            end
          end
        end

        def create_formatted_response(json_text)
          header = nil
          formatted_body = []

          json = JSON.parse(json_text)
          header = json.first
          body = json.last

          columns_with_type = body.first
          columns = columns_with_type.collect do |column, type|
            column.to_sym
          end

          tables = body[1..-1]
          tables.each.with_index do |table, n_table|
            formatted_body[n_table] = {}
            table.each.with_index do |table_value, n_column|
              column = columns[n_column]
              formatted_body[n_table][column] = table_value
            end
          end

          [header, formatted_body]
        end

        class TableInfo
          def initialize(table_info)
            @table_info = table_info
          end

          def id
            @table_info[:id]
          end

          def name
            @table_info[:name]
          end

          def path
            @table_info[:path]
          end

          def flags
            @table_info[:flags]
          end

          def domain
            @table_info[:domain]
          end

          def range
            @table_info[:range]
          end

          def default_tokenizer
            @table_info[:default_tokenizer]
          end

          def normalizer
            @table_info[:normalizer]
          end
        end
      end
    end
  end
end
