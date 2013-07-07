# -*- coding: utf-8 -*-
#
# Copyright (C) 2013  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2013  Kouhei Sutou <kou@clear-code.com>
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
        include Enumerable

        Response.register("column_list", self)

        def initialize(header, body)
          super(header, parse_body(body))
        end

        def each
          @columns.each do |column|
            yield column
          end
        end

        def size
          @columns.size
        end

        def [](index)
          @columns[index]
        end

        def parse_body(body)
          properties = body.first
          infos = body[1..-1]
          @columns = infos.collect do |info|
            column = Column.new
            properties.each_with_index do |(name, _), i|
              column.send("#{name}=", info[i])
            end
            column
          end
        end

        class Column < Struct.new(:id,
                                  :name,
                                  :path,
                                  :type,
                                  :flags,
                                  :domain,
                                  :range,
                                  :source)
        end
      end
    end
  end
end
