# Copyright (C) 2013  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2013-2024  Sutou Kouhei <kou@clear-code.com>
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

        def body=(body)
          super(body)
          parse_body(body)
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
                                  :source,
                                  :generator)
          # @return [String]
          #   The column name with table name such as `TABLE.COLUMN`.
          #
          # @since 0.5.4
          def full_name
            "#{domain}.#{name}"
          end

          # @return [::Array<String>]
          #   The flag names of the column.
          #
          # @since 0.5.3
          def flags
            (super || "").split("|")
          end

          # @return [Boolean]
          #   `true` if the column is a scalar column, `false` otherwise.
          #
          # @since 0.5.3
          def scalar?
            flags.include?("COLUMN_SCALAR")
          end

          # @return [Boolean]
          #   `true` if the column is a vector column, `false` otherwise.
          #
          # @since 0.5.3
          def vector?
            flags.include?("COLUMN_VECTOR")
          end

          # @return [Boolean]
          #   `true` if the column is an index column, `false` otherwise.
          #
          # @since 0.5.3
          def index?
            flags.include?("COLUMN_INDEX")
          end

          alias_method :sources, :source
        end
      end
    end
  end
end
