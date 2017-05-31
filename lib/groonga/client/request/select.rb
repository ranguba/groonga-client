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
        #      filter(:user, "alice").
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
        #   @param column_name [Symbol] The target column name.
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
        #        filter.in_values(:tags, "tag1", "tag2")
        #          # -> --filter 'in_values(tags, "tag1", "tag2")'
        #
        #   @example: Use geo_in_rectangle function
        #      request.
        #        filter.geo_in_rectangle(:location, "0x100", "100x0")
        #          # -> --filter 'geo_in_rectangle(location, "0x100", "100x0")'
        #
        #   @example Use geo_in_circle function
        #      request.
        #        filter.geo_in_circle(:location, "100x100", 300)
        #          # -> --filter 'geo_in_circle(location, "100x100", 300, "rectangle")'
        #
        #   @example Use between function
        #      request.
        #        filter.between(:age, 19, "include", 32, "include")
        #          # -> --filter 'between(age, 19, "include", 32, "include")'
        #
        #   @return [Groonga::Client::Request::Select::Filter]
        #     The new request object for setting a filter condition.
        #
        #   @since 0.4.3
        def filter(*args)
          n_args = args.size
          case n_args
          when 0
            Filter.new(self)
          when 1, 2
            expression_or_column_name, values_or_value = *args

            if values_or_value.nil? or values_or_value.is_a?(::Hash)
              expression = expression_or_column_name
              values = values_or_value
            else
              expression = "%{column} == %{value}"
              column_name = expression_or_column_name
              column_name = Filter.column_namify(column_name,
                                                 "first",
                                                 "#{self.class}\##{__method__}")
              values = {
                column: column_name,
                value: values_or_value,
              }
            end
            parameter = FilterExpressionParameter.new(expression, values)
            add_parameter(FilterMerger, parameter)
          else
            message =
              "wrong number of arguments (given #{n_args}, expected 0..2)"
            raise ArgumentError, message
          end
        end

        # Sets scorer.
        #
        # @return [Groonga::Client::Request::Select]
        #   The new request with the given scorer.
        #
        # @since 0.5.1
        #
        # @overload scorer(column_name)
        #
        #   Sets `_score = #{column_name}` scorer.
        #
        #   @example Use column value as score
        #      request.scorer(:rate)
        #          # -> --scorer '_score = rate'
        #
        #   @param column_name [Symbol] The column name to be used as score.
        #
        # @overload scorer(expression, values=nil)
        #
        #   Adds a `_score = #{expression % values}` scorer. If
        #   `expression` is already assignment form such as `_score =
        #   %{column}`, `_score = ` isn't prepended automatically.
        #
        #   @example Compute score by expression
        #      request.scorer("2 * rate")
        #          # -> --scorer '_score = 2 * rate'
        #
        #   @example Expand values
        #      request.scorer("2 * %{column}", column: :rate)
        #          # -> --scorer '_score = 2 * rate'
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
        def scorer(expression_or_column_name, values=nil)
          case expression_or_column_name
          when Symbol
            expression = "_score = %{column}"
            column_name = expression_or_column_name
            values = { column: column_name }
          when String
            expression = expression_or_column_name
            case expression
            when /\A\s*\z/
              expression = nil
            when /\A[_a-zA-Z\d]+\s*=/
              # have assignment such as "_score = "
            else
              expression = "_score = #{expression}"
            end
          else
            expression = expression_or_column_name
          end
          add_parameter(OverwriteMerger,
                        ScorerExpressionParameter.new(expression, values))
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

        class Filter
          class << self
            # @private
            def column_namify(column_name, ith, signature)
              return column_name unless column_name.is_a?(String)

              message = "column name (the #{ith} argument) of #{signature} "
              message << "should be Symbol: #{column_name.inspect}: "
              message << caller(2, 1)[0]
              warn(message)
              column_name.to_sym
            end
          end

          def initialize(request)
            @request = request
          end

          # Adds a `geo_in_rectangle` condition then return a new `select`
          # request object.
          #
          # @see http://groonga.org/docs/reference/functions/geo_in_rectangle.html
          #   geo_in_rectangle function in the Groonga document
          #
          # @overload geo_in_rectangle(column_name, top_left, bottom_right)
          #
          #   @example: Basic usage
          #      request.
          #        filter.geo_in_rectangle(:location, "0x100", "100x0").
          #          # -> --filter 'geo_in_rectangle(location, "0x100", "100x0")'
          #
          #   @param column_name [Symbol] The column name to be checked.
          #
          #   @!macro [new] geo_in_rectangle
          #
          #     @param top_left [String] The top left of the condition rectangle.
          #        `"#{LONGITUDE}x#{LATITUDE}"` is the point format.
          #
          #     @param bottom_right [String] The bottom right of the condition rectangle.
          #        `"#{LONGITUDE}x#{LATITUDE}"` is the point format.
          #
          #     @return [Groonga::Client::Request::Select]
          #        The new request with the given condition.
          #
          #   @macro geo_in_rectangle
          #
          # @overload geo_in_rectangle(point, top_left, bottom_right)
          #
          #   @example Basic usage
          #      request.
          #        filter.geo_in_rectangle("50x50", "0x100", "100x0").
          #          # -> --filter 'geo_in_rectangle("50x50", "0x100", "100x0")'
          #
          #   @param point [String] The point to be checked.
          #      `"#{LONGITUDE}x#{LATITUDE}"` is the point format.
          #
          #   @macro geo_in_rectangle
          #
          # @since 0.5.0
          def geo_in_rectangle(column_name_or_point,
                               top_left, bottom_right)
            expression = "geo_in_rectangle(%{column_name_or_point}"
            expression << ", %{top_left}"
            expression << ", %{bottom_right}"
            expression << ")"
            @request.filter(expression,
                            column_name_or_point: column_name_or_point,
                            top_left: top_left,
                            bottom_right: bottom_right)
          end

          # Adds a `geo_in_circle` condition then returns a new `select`
          # request object.
          #
          # @see http://groonga.org/docs/reference/functions/geo_in_circle.html
          #   geo_in_circle function in the Groonga document
          #
          # @overload geo_in_circle(column_name, center, radius, approximate_type="rectangle")
          #
          #   @example Basic usage
          #      request.
          #        filter.geo_in_circle(:location, "100x100", 300).
          #          # -> --filter 'geo_in_circle(location, "100x100", 300, "rectangle")'
          #
          #   @param column_name [Symbol] The column name to be checked.
          #
          #   @!macro [new] geo_in_circle_common
          #
          #     @param center [String] The center point of the condition circle.
          #        `"#{LONGITUDE}x#{LATITUDE}"` is the point format.
          #
          #     @param radius [Integer] The radius of the condition circle.
          #
          #     @param approximate_type
          #        ["rectangle", "sphere", "ellipsoid"]
          #        ("rectangle")
          #
          #        How to approximate geography to compute radius.
          #
          #        The default is `"rectangle"`.
          #
          #     @return [Groonga::Client::Request::Select]
          #       The new request with the given condition.
          #
          #   @macro geo_in_circle_common
          #
          # @overload geo_in_circle(point, center, radius, approximate_type="rectangle")
          #
          #   @example Basic usage
          #      request.
          #        filter.geo_in_circle("0x0", "100x100", 300).
          #          # -> --filter 'geo_in_circle("0x0", "100x100", 300, "rectangle")'
          #
          #   @param point [String] The point to be checked.
          #      `"#{LONGITUDE}x#{LATITUDE}"` is the point format.
          #
          #   @macro geo_in_circle_common
          #
          #
          # @since 0.5.0
          def geo_in_circle(column_name_or_point,
                            center,
                            radius_or_point,
                            approximate_type="rectangle")
            expression = "geo_in_circle(%{column_name_or_point}"
            expression << ", %{center}"
            expression << ", %{radius_or_point}"
            expression << ", %{approximate_type}"
            expression << ")"
            @request.filter(expression,
                            column_name_or_point: column_name_or_point,
                            center: center,
                            radius_or_point: radius_or_point,
                            approximate_type: approximate_type)
          end

          # Adds a `between` condition then returns a new `select`
          # request object.
          #
          # @see http://groonga.org/docs/reference/functions/between.html
          #   between function in the Groonga document
          #
          # @return [Groonga::Client::Request::Select]
          #   The new request with the given condition.
          #
          # @overload between(column_name, min, max, min_border: "include", max_border: "include")
          #
          #   @example Basic usage
          #      request.
          #        filter.between(:age, 19, 32)
          #          # -> --filter 'between(age, 19, "include", 32, "exclude")'
          #
          #   @!macro [new] between_common
          #
          #     @param column_name [Symbol] The target column name.
          #
          #     @param min [Integer] The minimal value of the
          #        condition range.
          #
          #     @param max [Integer] The maximum value of the
          #        condition range.
          #
          #     @param min_border ["include", "exclude"] Whether `min` is
          #        included or not. If `"include"` is specified, `min` is
          #        included. If `"exclude"` is specified, `min` isn't
          #        included.
          #
          #     @param max_border ["include", "exclude"] Whether `max` is
          #        included or not. If `"include"` is specified, `max` is
          #        included. If `"exclude"` is specified, `max` isn't
          #        included.
          #
          #   @macro between_common
          #
          #   @since 0.5.0
          #
          # @overload between(column_name, min, min_border, max, max_border)
          #
          #   @example Basic usage
          #      request.
          #        filter.between(:age, 19, "include", 32, "exclude")
          #          # -> --filter 'between(age, 19, "include", 32, "exclude")'
          #
          #   @macro between_common
          #
          #   @since 0.4.4
          def between(*args)
            n_args = args.size
            case n_args
            when 3
              column_name, min, max = args
              min_border = "include"
              max_border = "include"
            when 4
              column_name, min, max, options = args
              min_border = options[:min_border] || "include"
              max_border = options[:max_border] || "include"
            when 5
              column_name, min, min_border, max, max_border = args
            else
              message =
                "wrong number of arguments (given #{n_args}, expected 3..5)"
              raise ArgumentError, message
            end

            # TODO: Accept not only column name but also literal as
            # the first argument.
            column_name =
              self.class.column_namify(column_name,
                                       "first",
                                       "#{self.class}\##{__method__}")
            expression = "between(%{column_name}"
            expression << ", %{min}"
            expression << ", %{min_border}"
            expression << ", %{max}"
            expression << ", %{max_border}"
            expression << ")"
            @request.filter(expression,
                            column_name: column_name,
                            min: min,
                            min_border: min_border,
                            max: max,
                            max_border: max_border)
          end

          # Adds a `in_values` condition then returns a new `select`
          # request object.
          #
          # @example Multiple conditions
          #    request.
          #      filter.in_values(:tags, "tag1", "tag2").
          #        # -> --filter 'in_values(tags, "tag1", "tag2")'
          #      filter("user", "alice")
          #        # -> --filter '(in_values(tags, "tag1", "tag2")) && (user == "alice")'
          #
          # @example Ignore no values case
          #    request.
          #      filter.in_values(:tags)
          #        # -> --filter ''
          #
          # @see http://groonga.org/docs/reference/functions/in_values.html
          #   `in_values` function in the Groonga document
          #
          # @param column_name [Symbol] The target column name.
          #
          # @param values [Object] The column values that cover target
          #   column values.
          #
          # @return [Groonga::Client::Request::Select]
          #   The new request with the given condition.
          #
          # @since 0.4.3
          def in_values(column_name, *values)
            return @request if values.empty?

            # TODO: Accept not only column name but also literal as
            # the first argument.
            column_name =
              self.class.column_namify(column_name,
                                       "first",
                                       "#{self.class}\##{__method__}")
            expression_values = {column_name: column_name}
            expression = "in_values(%{column_name}"
            values.each_with_index do |value, i|
              expression << ", %{value#{i}}"
              expression_values[:"value#{i}"] = value
            end
            expression << ")"
            @request.filter(expression, expression_values)
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

        class ScorerExpressionParameter < ScriptSyntaxExpressionParameter
          def initialize(expression, values)
            super(:scorer, expression, values)
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
