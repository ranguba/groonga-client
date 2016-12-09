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

module Groonga
  class Client
    module Request
      class Select < Base
        class << self
          def command_name
            "select"
          end
        end

        def initialize(table_or_parameters, extensions=[])
          if table_or_parameters.respond_to?(:to_parameters)
            parameters = table_or_parameters
          else
            table_name = table_or_parameters
            parameters = RequestParameter.new(:table, table_name)
          end
          super(parameters, extensions)
        end

        def match_columns(value)
          add_parameter(OverwriteMerger,
                        MatchColumnsParameter.new(value))
        end

        def query(value)
          add_parameter(QueryMerger,
                        RequestParameter.new(:query, value))
        end

        def filter(expression, values=nil)
          add_parameter(FilterMerger,
                        FilterParameter.new(expression, values))
        end

        def output_columns(value)
          add_parameter(OverwriteMerger,
                        OutputColumnsParameter.new(value))
        end

        def sort_keys(value)
          add_parameter(OverwriteMerger,
                        SortKeysParameter.new(value))
        end
        alias_method :sortby, :sort_keys
        alias_method :sort, :sort_keys

        def offset(value)
          parameter(:offset, value)
        end

        def limit(value)
          parameter(:limit, value)
        end

        def paginate(page, per_page: 10)
          page ||= 1
          page = page.to_i
          if page <= 0
            offset = 0
          else
            offset = per_page * (page - 1)
          end
          offset(offset).limit(per_page)
        end

        private
        def create_response
          response = super
          if paginated? and defined?(Kaminari)
            response.extend(Kaminari::ConfigurationMethods::ClassMethods)
            response.extend(Kaminari::PageScopeMethods)
          end
          response
        end

        def paginated?
          parameters = to_parameters
          parameters.key?(:offset) and parameters.key?(:limit)
        end

        # @private
        class QueryMerger < ParameterMerger
          def to_parameters
            params1 = @parameters1.to_parameters
            params2 = @parameters2.to_parameters
            params = params1.merge(params2)
            query1 = params1[:query]
            query2 = params2[:query]
            if query1.present? and query2.present?
              params[:query] = "(#{query1}) (#{query2})"
            else
              params[:query] = (query1 || query2)
            end
            params
          end
        end

        # @private
        class FilterMerger < ParameterMerger
          def to_parameters
            params1 = @parameters1.to_parameters
            params2 = @parameters2.to_parameters
            params = params1.merge(params2)
            filter1 = params1[:filter]
            filter2 = params2[:filter]
            if filter1.present? and filter2.present?
              params[:filter] = "(#{filter1}) && (#{filter2})"
            else
              params[:filter] = (filter1 || filter2)
            end
            params
          end
        end

        # @private
        class MatchColumnsParameter
          def initialize(match_columns)
            @match_columns = match_columns
          end

          def to_parameters
            case @match_columns
            when ::Array
              return {} if @match_columns.empty?
              match_columns = @match_columns.join(", ")
            when Symbol
              match_columns = @match_columns.to_s
            when String
              return {} if /\A\s*\z/ === @match_columns
              match_columns = @match_columns
            when NilClass
              return {}
            else
              match_columns = @match_columns
            end
            {
              match_columns: match_columns,
            }
          end
        end

        # @private
        class FilterParameter
          def initialize(expression, values)
            @expression = expression
            @values = values
          end

          def to_parameters
            case @expression
            when String
              return {} if /\A\s*\z/ === @expression
              expression = @expression
            when NilClass
              return {}
            else
              expression = @expression
            end

            if @values.is_a?(::Hash) and not @values.empty?
              escaped_values = {}
              @values.each do |key, value|
                escaped_values[key] = escape_filter_value(value)
              end
              expression = expression % escaped_values
            end

            {
              filter: expression,
            }
          end

          private
          def escape_filter_value(value)
            case value
            when Numeric
              value
            when TrueClass, FalseClass
              value
            when NilClass
              "null"
            when String
              ScriptSyntax.format_string(value)
            when Symbol
              ScriptSyntax.format_string(value.to_s)
            when ::Array
              escaped_value = "["
              value.each_with_index do |element, i|
                escaped_value << ", " if i > 0
                escaped_value << escape_filter_value(element)
              end
              escaped_value << "]"
              escaped_value
            when ::Hash
              escaped_value = "{"
              value.each_with_index do |(k, v), i|
                escaped_value << ", " if i > 0
                escaped_value << escape_filter_value(k.to_s)
                escaped_value << ": "
                escaped_value << escape_filter_value(v)
              end
              escaped_value << "}"
              escaped_value
            else
              value
            end
          end
        end

        # @private
        class OutputColumnsParameter
          def initialize(output_columns)
            @output_columns = output_columns
          end

          def to_parameters
            case @output_columns
            when ::Array
              return {} if @output_columns.empty?
              output_columns = @output_columns.join(", ")
            when Symbol
              output_columns = @output_columns.to_s
            when String
              return {} if /\A\s*\z/ === @output_columns
              output_columns = @output_columns
            when NilClass
              return {}
            else
              output_columns = @output_columns
            end

            parameters = {
              output_columns: output_columns,
            }
            if output_columns.include?("(")
              parameters[:command_version] = "2"
            end
            parameters
          end
        end

        # @private
        class SortKeysParameter
          def initialize(keys)
            @keys = keys
          end

          def to_parameters
            case @keys
            when ::Array
              return {} if @keys.empty?
              keys = @keys.collect(&:to_s).join(", ")
            when Symbol
              keys = @keys.to_s
            when String
              return {} if /\A\s*\z/ === @keys
              keys = @keys
            when NilClass
              return {}
            else
              keys = @keys
            end
            {
              sort_keys: keys,
              sortby: keys, # For backward compatibility
            }
          end
        end
      end
    end
  end
end
