# Copyright (C) 2016  Kouhei Sutou <kou@clear-code.com>
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
      # The response class for `schema` command.
      #
      # @since 0.2.2
      class Schema < Base
        Response.register("schema", self)

        # @return [Hash<String, Type>] Key is type name and
        #   value is the definition of the type.
        #
        # @since 0.2.2
        def types
          @types ||= HashValueConverter.convert(@body["types"]) do |raw_type|
            Type[raw_type]
          end
        end

        # @return [Hash<String, Tokenizer>] Key is tokenizer name and
        #   value is the definition of the tokenizer.
        #
        # @since 0.2.2
        def tokenizers
          @tokenizers ||= HashValueConverter.convert(@body["tokenizers"]) do |tokenizer|
            Tokenizer[tokenizer]
          end
        end

        # @return [Hash<String, Normalizer>] Key is normalizer name and
        #   value is the definition of the normalizer.
        #
        # @since 0.2.3
        def normalizers
          @normalizers ||= HashValueConverter.convert(@body["normalizers"]) do |normalizer|
            Normalizer[normalizer]
          end
        end

        # @return [Hash<String, TokenFilter>] Key is token filter name and
        #   value is the definition of the token filter.
        #
        # @since 0.2.3
        def token_filters
          @token_filters ||= HashValueConverter.convert(@body["token_filters"]) do |token_filter|
            TokenFilter[token_filter]
          end
        end

        # @return [Hash<String, Table>] Key is table name and value is the
        #   definition of the table.
        #
        # @since 0.2.2
        def tables
          @tables ||= nil
          return @tables if @tables

          @tables = {}
          @body["tables"].each do |key, _|
            @tables[key] = Table.new(self)
          end
          @body["tables"].each do |key, raw_table|
            table = @tables[key]
            raw_table.each do |table_key, table_value|
              table[table_key] = table_value
            end
          end
          @tables
        end

        private
        def coerce_tables
        end

        module HashValueConverter
          class << self
            def convert(hash)
              converted = {}
              hash.each do |key, value|
                converted[key] = yield(value)
              end
              converted
            end
          end
        end

        class Type < ::Hash
          include Hashie::Extensions::MergeInitializer
          include Hashie::Extensions::MethodAccess
        end

        class Tokenizer < ::Hash
          include Hashie::Extensions::MergeInitializer
          include Hashie::Extensions::MethodAccess
        end

        class Normalizer < ::Hash
          include Hashie::Extensions::MergeInitializer
          include Hashie::Extensions::MethodAccess
        end

        class TokenFilter < ::Hash
          include Hashie::Extensions::MergeInitializer
          include Hashie::Extensions::MethodAccess
        end

        class KeyType < ::Hash
          include Hashie::Extensions::MergeInitializer
          include Hashie::Extensions::MethodAccess
        end

        class ValueType < ::Hash
          include Hashie::Extensions::MergeInitializer
          include Hashie::Extensions::MethodAccess
        end

        class Index < ::Hash
          include Hashie::Extensions::MethodAccess

          def initialize(schema, raw_index)
            @schema = schema
            super()
            raw_index.each do |key, value|
              self[key] = value
            end
          end

          def []=(key, value)
            case key.to_sym
            when :table
              super(key, coerce_table(value))
            else
              super
            end
          end

          def column
            column_name = name
            if column_name.nil?
              column_name
            else
              table.columns[column_name]
            end
          end

          def full_text_searchable?
            table.tokenizer and column.position
          end

          private
          def coerce_table(table_name)
            @schema.tables[table_name]
          end
        end

        class Column < ::Hash
          include Hashie::Extensions::MethodAccess

          def initialize(schema, raw_column)
            @schema = schema
            super()
            raw_column.each do |key, value|
              self[key] = value
            end
          end

          def []=(key, value)
            case key.to_sym
            when :indexes
              super(key, coerce_indexes(value))
            when :value_type
              super(key, ValueType.new(value))
            else
              super
            end
          end

          def have_full_text_search_index?
            indexes.any? do |index|
              index.full_text_searchable?
            end
          end

          private
          def coerce_indexes(raw_indexes)
            raw_indexes.collect do |raw_index|
              Index.new(@schema, raw_index)
            end
          end
        end

        class Table < ::Hash
          include Hashie::Extensions::MethodAccess

          def initialize(schema)
            @schema = schema
            super()
          end

          def []=(key, value)
            case key.to_sym
            when :key_type
              super(key, coerce_key_type(value))
            when :tokenizer
              super(key, coerce_tokenizer(value))
            when :normalizer
              super(key, coerce_normalizer(value))
            when :columns
              super(key, coerce_columns(value))
            when :indexes
              super(key, coerce_indexes(value))
            else
              super
            end
          end

          def have_full_text_search_index?
            indexes.any? do |index|
              index.full_text_searchable?
            end
          end

          private
          def coerce_key_type(raw_key_type)
            if raw_key_type.nil?
              nil
            elsif raw_key_type["type"] == "type"
              @schema.types[raw_key_type["name"]]
            else
              @schema.tables[raw_key_type["name"]]
            end
          end

          def coerce_tokenizer(raw_tokenizer)
            if raw_tokenizer.nil?
              nil
            else
              @schema.tokenizers[raw_tokenizer["name"]]
            end
          end

          def coerce_normalizer(raw_normalizer)
            if raw_normalizer.nil?
              nil
            else
              @schema.normalizers[raw_normalizer["name"]]
            end
          end

          def coerce_token_filters(raw_token_filters)
            raw_token_filters.collect do |raw_token_filter|
              TokenFilter[raw_token_filter]
            end
          end

          def coerce_columns(raw_columns)
            HashValueConverter.convert(raw_columns) do |raw_column|
              Column.new(@schema, raw_column)
            end
          end

          def coerce_indexes(raw_indexes)
            raw_indexes.collect do |raw_index|
              Index.new(@schema, raw_index)
            end
          end
        end
      end
    end
  end
end
