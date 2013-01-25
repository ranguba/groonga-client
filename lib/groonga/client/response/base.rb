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

require "json"

module Groonga
  class Client
    module Response
      class << self
        @@registered_commands = {}
        def register(name, klass)
          @@registered_commands[name] = klass
        end

        def find(name)
          @@registered_commands[name] || Base
        end
      end

      class Base
        attr_accessor :header, :body

        def initialize(json)
          if json.nil?
            @header = nil
            @body = nil
          else
            response = JSON.parse(json)
            @header = response.first
            @body = response.last
          end
        end

        def format_response(json)
          header = nil
          formatted_body = []

          json = JSON.parse(json)
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
      end
    end
  end
end
