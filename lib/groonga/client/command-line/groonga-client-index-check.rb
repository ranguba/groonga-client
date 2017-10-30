# Copyright (C) 2015-2017  Kouhei Sutou <kou@clear-code.com>
# Copyright (C) 2017 Kentaro Hayashi <hayashi@clear-code.com>
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

require "groonga/client"
require "groonga/client/command-line/parser"
require "groonga/client/command-line/runner"

module Groonga
  class Client
    module CommandLine
      class GroongaClientIndexCheck
        def initialize
          @available_methods = [:source, :content]
          @methods = []
        end

        def run(arguments)
          parser = Parser.new
          indexe_names = parser.parse(arguments) do |option_parser|
            parse_command_line(option_parser)
          end

          if @methods.empty?
            @methods = @available_methods
          end

          parser.open_client do |client|
            checker = Checker.new(client, @methods, indexe_names)
            checker.run
          end
        end

        private
        def parse_command_line(parser)
          parser.banner += " [LEXICON1.INDEX1 LEXICON2.INDEX2 ...]"

          parser.separator("")
          parser.separator("If no indexes are specified, " +
                           "all indexes are checked.")

          parser.separator("")
          parser.separator("Method:")

          parser.on("--method=METHOD", @available_methods,
                    "Specify a method how to check indexes.",
                    "You can specify this option multiple times",
                    "to use multiple methods in one execution.",
                    "All methods are used by default.",
                    "Available methods:",
                    "  source: Find indexes that don't have source.",
                    "  content: Find indexes that their content is broken.",
                    "(#{@available_methods.join(", ")})") do |method|
            @methods << method
          end
        end

        class Checker < Runner
          def initialize(client, methods, index_names)
            super(client)
            @methods = methods
            @index_names = index_names
          end

          private
          def run_internal
            succeeded = true
            each_target_index_column do |index_column|
              @methods.each do |method|
                unless __send__("check_#{method}", index_column)
                  succeeded = false
                end
              end
            end
            succeeded
          end

          def each_target_index_column
            table_list.each do |table|
              next unless check_target_table?(table.name)
              column_list(table.name).each do |column|
                next unless check_target_column?(column)
                next unless column.index?
                yield(column)
              end
            end
          end

          def check_target_table?(table_name)
            unless @index_names.count > 0
              return true
            end
            if @index_names.kind_of?(Array)
              @index_names.each do |name|
                table_part = name.split(".").first
                return true if table_name == table_part
              end
            end
            false
          end

          def check_target_column?(column)
            unless @index_names.count > 0
              return column["type"] == "index"
            else
              unless column["type"] == "index"
                return false
              end
            end
            if @index_names.kind_of?(Array)
              @index_names.each do |name|
                return true if name == "#{column['domain']}.#{column['name']}" or
                  name == column["domain"]
              end
            end
            false
          end

          def check_source(column)
            return true unless column.source.empty?
            $stderr.puts("Source is missing: <#{column.domain}.#{column.name}>")
            false
          end

          def list_tokens(table_name)
            response = execute_command(:select,
                                       :table => table_name,
                                       :limit => "-1",
                                       :output_columns => "_key")
            response.records.collect do |record|
              record["_key"]
            end
          end

          def verify_tokens(table_name, old_column, new_column, tokens)
            broken_index_tokens = []
            tokens.each do |token|
              query = Groonga::Client::ScriptSyntax.format_string(token)
              old_response = execute_command(:select,
                                             :table => table_name,
                                             :match_columns => old_column,
                                             :query => query,
                                             :output_columns => "_id",
                                             :limit => "-1",
                                             :sort_keys => "_id")
              new_response = execute_command(:select,
                                             :table => table_name,
                                             :match_columns => new_column,
                                             :query => query,
                                             :output_columns => "_id",
                                             :limit => "-1",
                                             :sort_keys => "_id")
              old_response_ids = old_response.records.collect do |value|
                value["_id"]
              end
              new_response_ids = new_response.records.collect do |value|
                value["_id"]
              end
              if old_response_ids != new_response_ids
                broken_index_tokens << token
              end
            end
            broken_index_tokens
          end

          def check_content(index_column)
            return if index_column.source.empty?

            table_name = index_column["domain"]
            column_name = index_column["name"]
            suffix = Time.now.strftime("%Y%m%d%H%M%S_%N")
            new_column_name = "#{column_name}_#{suffix}"
            type, source = index_column.sources.first.split(".")
            flags = index_column["flags"].split("|")
            flags.delete("PERSISTENT")
            column_create(table_name,
                          new_column_name,
                          flags.join("|"),
                          type,
                          source)
            begin
              tokens = list_tokens(table_name)
              broken_index_tokens = verify_tokens(table_name, column_name,
                                                  new_column_name, tokens)
            ensure
              column_remove(table_name, new_column_name)
            end
            if broken_index_tokens.empty?
              true
            else
              $stderr.puts("Broken: #{table_name}.#{column_name}")
              false
            end
          end
        end
      end
    end
  end
end
