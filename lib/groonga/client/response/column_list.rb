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
      class ColumnList < Base
        Response.register("column_list", self)

        def initialize(json_text)
          if json_text.nil?
            @header = nil
            @body = nil
          else
            @header, column_infos = format_response(json_text)
            @body = column_infos.collect do |column_info|
              ColumnInfo.new(column_info)
            end
          end
        end

        def format_response(json_text)
          header = nil
          formatted_body = []

          json = JSON.parse(json_text)
          header = json.first
          body = json.last

          columns_with_type = body.first
          columns = columns_with_type.collect do |column, type|
            column.to_sym
          end

          entries = body[1..-1]
          entries.each.with_index do |entry, n_entry|
            formatted_body[n_entry] = {}
            entry.each.with_index do |value, n_value|
              column = columns[n_value]
              formatted_body[n_entry][column] = value
            end
          end

          [header, formatted_body]
        end

        class ColumnInfo
          attr_reader :column_info

          def initialize(column_info)
            @column_info = column_info
          end

          def id
            @column_info[:id]
          end

          def name
            @column_info[:name]
          end

          def path
            @column_info[:path]
          end

          def flags
            @column_info[:flags]
          end

          def domain
            @column_info[:domain]
          end

          def range
            @column_info[:range]
          end

          def source
            @column_info[:source]
          end
        end
      end
    end
  end
end
