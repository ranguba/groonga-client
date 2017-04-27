# Copyright (C) 2016-2017  Kouhei Sutou <kou@clear-code.com>
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
      class Select < Generic
        include Enumerable

        class << self
          def command_name
            "select"
          end
        end

        Request.register(self)

        def initialize(table_or_parameters, extensions=[])
          if table_or_parameters.respond_to?(:to_parameters)
            parameters = table_or_parameters
          else
            table_name = table_or_parameters
            parameters = RequestParameter.new(:table, table_name)
          end
          super(parameters, extensions)
        end

        def match_columns(values)
          values_parameter([:match_columns], values)
        end

        def query(value)
          add_parameter(QueryMerger,
                        RequestParameter.new(:query, value))
        end

        # Adds a script syntax condition. If the request already has
        # any filter condition, they are combined by AND.
        #
        # @example Multiple filters
        #    request.
        #      filter("user", "alice").
        #        # -> --filter 'user == "alice"'
        #      filter("tags @ %{tag}", tag: "Ruby")
        #        # -> --filter '(user == "alice") && (tags @ "Ruby")'
        #
        # @return [Groonga::Client::Request::Select]
        #   The new request with the given condition.
        #
        # @overload filter(column_name, value)
        #   Adds a `#{column_name} == #{value}` condition.
        #
        #   @param column_name [String, Symbol] The target column name.
        #
        #   @param value [Object] The column value. It's escaped
        #     automatically.
        #
        # @overload filter(expression, values=nil)
        #
        #   Adds a `#{expression % values}` condition.
        #
        #   @param expression [String] The script syntax expression.
        #      It can includes `%{name}`s as placeholder. They are expanded
        #      by `String#%` with the given `values` argument.
        #
        #   @param values [nil, ::Hash] The values to be expanded.
        #      If the given `expression` doesn't have placeholder, you
        #      should specify `nil`.
        #
        #      Values are escaped automatically. Values passed from
        #      external should be escaped.
        #
        # @overload filter
        #
        #   Returns a request object for filter condition. It provides
        #   convenient methods to add a popular filter condition.
        #
        #   @example Use in_values function
        #      request.
        #        filter.in_values("tags", "tag1", "tag2")
        #          # -> --filter 'in_values(tags, "tag1", "tag2")'
        #
        #   @example Use geo_in_circle function
        #      request.
        #        filter.geo_in_circle("0x0", "100x100", 300)
        #          # -> --filter 'geo_in_circle("0x0", "100x100", 300, "rectangle")'
        #
        #   @example Use between function
        #      request.
        #        filter.between("age", 19, "include", 32, "include")
        #          # -> --filter 'between(age, 19, "include", 32, "include")'
        #
        #   @return [Groonga::Client::Request::Select::Filter]
        #     The new request object for setting a filter condition.
        #
        #   @since 0.4.3
        def filter(expression_or_column_name=nil, values_or_value=nil)
          if expression_or_column_name.nil? and values_or_value.nil?
            return Filter.new(self)
          end

          if expression_or_column_name.is_a?(Symbol)
            parameter = FilterEqualParameter.new(expression_or_column_name,
                                                 values_or_value)
          elsif values_or_value.nil? or values_or_value.is_a?(::Hash)
            parameter = FilterExpressionParameter.new(expression_or_column_name,
                                                      values_or_value)
          else
            parameter = FilterEqualParameter.new(expression_or_column_name,
                                                 values_or_value)
          end
          add_parameter(FilterMerger, parameter)
        end

        def output_columns(value)
          add_parameter(OverwriteMerger,
                        OutputColumnsParameter.new("", value))
        end

        def sort_keys(value)
          add_parameter(OverwriteMerger,
                        BackwardCompatibleSortKeysParameter.new("", value))
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
          per_page = per_page.to_i
          per_page = 10 if per_page <= 0

          if page <= 0
            offset = 0
          else
            offset = per_page * (page - 1)
          end
          offset(offset).limit(per_page)
        end

        def drilldowns(label)
          LabeledDrilldown.new(self, label)
        end

        def columns(label)
          DynamicColumn.new(self, label)
        end

        def each(&block)
          response.records.each(&block)
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

        # @since 0.4.3
        class Filter
          def initialize(request)
            @request = request
          end

          # Adds a `geo_in_circle` condition then return a new `select`
          # request object.
          #
          # @example Basic usage
          #    request.
          #      filter.geo_in_circle("0x0", "100x100", 300).
          #        # -> --filter 'geo_in_circle("0x0", "100x100", 300, "rectangle")'
          #
          # @see http://groonga.org/docs/reference/functions/geo_in_circle.html
          #   geo_in_circle function in the Groonga document
          #
          # @param point [String] Specify point for confirm whether to exit in circle or not.
          #
          # @param center [String] This value that center of circle.
          #
          # @param radious [Integer] This value that radious of circle.
          #
          # @param approximate_type ["rectangle", "sphere", "ellopsoid"]
          #    This value that type of approximate of geographical.
          #    If it is nil, approximate_type value is `"rectangle"`.
          #    If it is `"rectangle"`, calcurate distance from radious
          #    by approximate of rectangle.
          #    If it is `"sphere"`, calcurate distance from radious
          #    by approximate of sphere.
          #    If it is `"ellopsoid"`, calcurate distance from radious
          #    by approximate of ellopsoid.
          #
          # @return [Groonga::Client::Request::Select]
          #   The new request with the given condition.
          #
          # @since 0.4.4
          def geo_in_circle(point, center, radious_or_point, approximate_type="rectangle")
            parameter = FilterGeoInCircleParameter.new(point,
                                                       center, radious_or_point,
                                                       approximate_type)
            add_parameter(FilterMerger, parameter)
          end

          # Adds a `between` condition then return a new `select`
          # request object.
          #
          # @example Basic usage
          #    request.
          #      filter.between("age", 19, "include", 32, "exclude").
          #        # -> --filter 'between(age, 19, "include", 32, "exclude")'
          #
          # @see http://groonga.org/docs/reference/functions/between.html
          #   between function in the Groonga document
          #
          # @param column_name [String, Symbol] The target column name.
          #
          # @param min [Integer] The minimal value of the condition
          #   range.
          #
          # @param min_border ["include", "exclude"] Whether `min` is
          #    included or not. If `"include"` is specified, `min` is
          #    included. If `"exclude"` is specified, `min` isn't
          #    included.
          #
          # @param max [Integer] The maximum value of the condition
          #   range.
          #
          # @param max_border ["include", "exclude"] Whether `max` is
          #    included or not. If `"include"` is specified, `max` is
          #    included. If `"exclude"` is specified, `max` isn't
          #    included.
          #
          # @return [Groonga::Client::Request::Select]
          #   The new request with the given condition.
          #
          # @since 0.4.4
          def between(column_name, min, *args, min_border: :include, max_border: :include)
            case args.size
            when 1
              max = args[0]
            when 2
              min_border = args[0]
              max = args[1]
            when 3
              min_border = args[0]
              max = args[1]
              max_border = args[2]
            end
            parameter = FilterBetweenParameter.new(column_name,
                                                   min, min_border,
                                                   max, max_border)
            add_parameter(FilterMerger, parameter)
          end

          # Adds a `in_values` condition then return a new `select`
          # request object.
          #
          # @example Multiple conditions
          #    request.
          #      filter.in_values("tags", "tag1", "tag2").
          #        # -> --filter 'in_values(tags, "tag1", "tag2")'
          #      filter("user", "alice")
          #        # -> --filter '(in_values(tags, "tag1", "tag2")) && (user == "alice")'
          #
          # @example Ignore no values case
          #    request.
          #      filter.in_values("tags")
          #        # -> --filter ''
          #
          # @see http://groonga.org/docs/reference/functions/in_values.html
          #   `in_values` function in the Groonga document
          #
          # @param column_name [String, Symbol] The target column name.
          #
          # @param values [Object] The column values that cover target
          #   column values.
          #
          # @return [Groonga::Client::Request::Select]
          #   The new request with the given condition.
          def in_values(column_name, *values)
            parameter = FilterInValuesParameter.new(column_name, *values)
            add_parameter(FilterMerger, parameter)
          end

          private
          def add_parameter(merger, parameter)
            @request.__send__(:add_parameter, merger, parameter)
          end
        end

        class LabeledDrilldown
          def initialize(request, label)
            @request = request
            @label = label
          end

          def keys(values)
            @request.values_parameter([:"#{prefix}keys"], values)
          end

          def sort_keys(value)
            add_parameter(OverwriteMerger,
                          BackwardCompatibleSortKeysParameter.new(prefix, value))
          end
          alias_method :sortby, :sort_keys
          alias_method :sort, :sort_keys

          def output_columns(value)
            add_parameter(OverwriteMerger,
                          OutputColumnsParameter.new(prefix, value))
          end

          def offset(value)
            @request.parameter(:"#{prefix}offset", value)
          end

          def limit(value)
            @request.parameter(:"#{prefix}limit", value)
          end

          def calc_types(value)
            @request.flags_parameter(:"#{prefix}calc_types", value)
          end

          def calc_target(value)
            @request.parameter(:"#{prefix}calc_target", value)
          end

          private
          def prefix
            "drilldowns[#{@label}]."
          end

          def add_parameter(merger, parameter)
            @request.__send__(:add_parameter, merger, parameter)
          end
        end

        class DynamicColumn
          def initialize(request, label)
            @request = request
            @label = label
          end

          def stage(value)
            add_parameter(OverwriteMerger,
                          RequestParameter.new(:"#{prefix}stage", value))
          end

          def type(value)
            add_parameter(OverwriteMerger,
                          RequestParameter.new(:"#{prefix}type", value))
          end

          def flags(value)
            @request.flags_parameter(:"#{prefix}flags", value)
          end

          def value(expression, values=nil)
            add_parameter(OverwriteMerger,
                          ScriptSyntaxExpressionParameter.new(:"#{prefix}value",
                                                              expression,
                                                              values))
          end

          def window
            DynamicColumnWindow.new(@request, @label)
          end

          private
          def prefix
            "columns[#{@label}]."
          end

          def add_parameter(merger, parameter)
            @request.__send__(:add_parameter, merger, parameter)
          end
        end

        class DynamicColumnWindow
          def initialize(request, label)
            @request = request
            @label = label
          end

          def sort_keys(value)
            add_parameter(OverwriteMerger,
                          SortKeysParameter.new(prefix, value))
          end
          alias_method :sortby, :sort_keys
          alias_method :sort, :sort_keys

          # Sets `columns[LABEL].window.group_keys` parameter.
          #
          # @return [Groonga::Client::Request::Select] The current
          #   request object.
          #
          # @since 0.4.1
          def group_keys(values)
            @request.values_parameter([:"#{prefix}group_keys"], values)
          end

          private
          def prefix
            "columns[#{@label}].window."
          end

          def add_parameter(merger, parameter)
            @request.__send__(:add_parameter, merger, parameter)
          end
        end

        # @private
        class QueryMerger < ParameterMerger
          def to_parameters
            params1 = @parameters1.to_parameters
            params2 = @parameters2.to_parameters
            params = params1.merge(params2)
            query1 = params1[:query]
            query2 = params2[:query]
            if query1 and query2
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
            if filter1 and filter2
              params[:filter] = "(#{filter1}) && (#{filter2})"
            elsif filter1 or filter2
              params[:filter] = (filter1 || filter2)
            end
            params
          end
        end

        # @private
        module ScriptSyntaxValueEscapable
          private
          def escape_script_syntax_value(value)
            case value
            when Numeric
              value.to_s
            when TrueClass, FalseClass
              value.to_s
            when NilClass
              "null"
            when String
              ScriptSyntax.format_string(value)
            when Symbol
              if valid_script_syntax_identifier?(value)
                value.to_s
              else
                ScriptSyntax.format_string(value.to_s)
              end
            when ::Array
              escaped_value = "["
              value.each_with_index do |element, i|
                escaped_value << ", " if i > 0
                escaped_value << escape_script_syntax_value(element)
              end
              escaped_value << "]"
              escaped_value
            when ::Hash
              escaped_value = "{"
              value.each_with_index do |(k, v), i|
                escaped_value << ", " if i > 0
                escaped_value << escape_script_syntax_value(k.to_s)
                escaped_value << ": "
                escaped_value << escape_script_syntax_value(v)
              end
              escaped_value << "}"
              escaped_value
            else
              value
            end
          end

          identifier_part = "[a-zA-Z_][a-zA-Z0-9_]*"
          VALID_SCRIPT_SYNTAX_IDENTIFIER_PATTERN =
            /\A#{identifier_part}(?:\.#{identifier_part})*\z/
          def valid_script_syntax_identifier?(value)
            VALID_SCRIPT_SYNTAX_IDENTIFIER_PATTERN === value.to_s
          end
        end

        # @private
        class ScriptSyntaxExpressionParameter
          include ScriptSyntaxValueEscapable

          def initialize(name, expression, values)
            @name = name
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

            case @values
            when ::Hash
              escaped_values = {}
              @values.each do |key, value|
                escaped_values[key] = escape_script_syntax_value(value)
              end
              expression = expression % escaped_values
            when ::Array
              escaped_values = @values.collect do |value|
                escape_script_syntax_value(value)
              end
              expression = expression % escaped_values
            end

            {
              @name => expression,
            }
          end
        end

        class FilterExpressionParameter < ScriptSyntaxExpressionParameter
          def initialize(expression, values)
            super(:filter, expression, values)
          end
        end

        # @private
        class FilterGeoInCircleParameter
          include ScriptSyntaxValueEscapable

          def initialize(point,
                         center, radious,
                         approximate_type)
            @point = point
            @center = center
            @radious = radious
            @approximate_type = approximate_type
          end

          def to_parameters
            filter = "geo_in_circle(#{escape_script_syntax_value(@point)}"
            filter << ", #{escape_script_syntax_value(@center)}"
            filter << ", #{escape_script_syntax_value(@radious)}"
            filter << ", #{escape_script_syntax_value(@approximate_type)}"
            filter << ")"
            {
              filter: filter,
            }
          end
        end

        class FilterBetweenParameter
          include ScriptSyntaxValueEscapable

          def initialize(column_name,
                         min, min_border,
                         max, max_border)
            @column_name = column_name
            @min = min
            @min_border = min_border
            @max = max
            @max_border = max_border
          end

          def to_parameters
            filter = "between(#{@column_name}"
            filter << ", #{escape_script_syntax_value(@min)}"
            filter << ", #{escape_script_syntax_value(@min_border)}"
            filter << ", #{escape_script_syntax_value(@max)}"
            filter << ", #{escape_script_syntax_value(@max_border)}"
            filter << ")"
            {
              filter: filter,
            }
          end
        end

        # @private
        class FilterInValuesParameter
          include ScriptSyntaxValueEscapable

          def initialize(column_name, *values)
            @column_name = column_name
            @values = values
          end

          def to_parameters
            return {} if @values.empty?

            escaped_values = @values.collect do |value|
              escape_script_syntax_value(value)
            end
            {
              filter: "in_values(#{@column_name}, #{escaped_values.join(", ")})",
            }
          end
        end

        class FilterEqualParameter
          include ScriptSyntaxValueEscapable

          def initialize(column_name, value)
            @column_name = column_name
            @value = value
          end

          def to_parameters
            {
              filter: "#{@column_name} == #{escape_script_syntax_value(@value)}",
            }
          end
        end

        # @private
        class OutputColumnsParameter < ValuesParameter
          def initialize(prefix, output_columns)
            super([:"#{prefix}output_columns"], output_columns)
          end

          def to_parameters
            parameters = super
            @names.each do |name|
              output_columns = parameters[name]
              if output_columns and output_columns.include?("(")
                parameters[:command_version] = "2"
                break
              end
            end
            parameters
          end
        end

        # @private
        class SortKeysParameter < ValuesParameter
          def initialize(prefix, output_columns)
            names = [
              :"#{prefix}sort_keys",
            ]
            super(names, output_columns)
          end
        end

        # @private
        class BackwardCompatibleSortKeysParameter < ValuesParameter
          def initialize(prefix, output_columns)
            names = [
              :"#{prefix}sort_keys",
              :"#{prefix}sortby", # for backward compatibility
            ]
            super(names, output_columns)
          end
        end
      end
    end
  end
end
