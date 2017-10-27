# Copyright (C) 2017  Kouhei Sutou <kou@clear-code.com>
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

require "groonga/client"
require "groonga/client/command-line/parser"
require "groonga/client/command-line/runner"

module Groonga
  class Client
    module CommandLine
      class GroongaClientIndexRecreate
        def initialize
          @interval = :day

          @n_workers = 0
        end

        def run(arguments)
          parser = Parser.new(:read_timeout => -1)
          indexes = parser.parse(arguments) do |option_parser|
            parse_command_line(option_parser)
          end

          parser.open_client do |client|
            recreator = Recreator.new(client, @interval, indexes)
            recreator.run do
              @n_workers.times do
                client.database_unmap
              end
            end
          end
        end

        private
        def parse_command_line(parser)
          parser.banner += " LEXICON1.INDEX1 LEXICON2.INDEX2 ..."

          parser.separator("")
          parser.separator("Configuration:")

          available_intervals = [:day]
          parser.on("--interval=INTERVAL", available_intervals,
                    "Index create interval.",
                    "[#{available_intervals.join(", ")}]",
                    "(#{@interval})") do |interval|
            @interval = interval
          end

          parser.separator("")
          parser.separator("groonga-httpd:")

          parser.on("--n-workers=N", Integer,
                    "The number of groonga-httpd workers.",
                    "This options is meaningless for groonga -s.",
                    "(#{@n_workers})") do |n|
            @n_workers = n
          end
        end

        class Recreator < Runner
          def initialize(client, interval, target_indexes)
            super(client)
            @interval = interval
            @target_indexes = target_indexes
            @now = Time.now
          end

          private
          def run_internal
            alias_column = ensure_alias_column
            @target_indexes.each do |index|
              current_index = recreate_index(index, alias_column)
              remove_old_indexes(index, current_index)
            end
            yield if block_given?
            true
          end

          def config_get(key)
            execute_command(:config_get, :key => key).body
          end

          def config_set(key, value)
            execute_command(:config_set, :key => key, :value => value).body
          end

          def object_exist?(name)
            execute_command(:object_exist, :name => name).body
          end

          def column_rename(table, name, new_name)
            execute_command(:column_rename,
                            :table => table,
                            :name => name,
                            :new_name => new_name).body
          end

          def column_list(table)
            execute_command(:column_list, :table => table)
          end

          def column_remove(table, column)
            execute_command(:column_remove,
                            :table => table,
                            :name => column)
          end

          def column_create_similar(table, column_name, base_column_name)
            info = execute_command(:schema)["#{table}.#{base_column_name}"]
            arguments = info.command.arguments.merge("name" => column_name)
            execute_command(:column_create, arguments).body
          end

          def set_alias(alias_column, alias_name, real_name)
            table, column = alias_column.split(".", 2)
            values = [
              {
                "_key" => alias_name,
                column => real_name,
              },
            ]
            response = execute_command(:load,
                                       :table => table,
                                       :values => JSON.generate(values),
                                       :command_version => "3",
                                       :output_errors => "yes")
            response.errors.each do |error|
              unless error.return_code.zero?
                abort_run("Failed to set alias: " +
                          "<#{alias_name}> -> <#{real_name}>: " +
                          "#{error.message}(#{error.return_code})")
              end
            end
          end

          def resolve_alias(alias_column, key)
            table, column = alias_column.split(".", 2)
            filter = "_key == #{ScriptSyntax.format_string(key)}"
            response = execute_command(:select,
                                       :table => table,
                                       :filter => filter,
                                       :output_columns => column)
            return nil if response.n_hits.zero?
            response.records.first[column]
          end

          def ensure_alias_column
            alias_column = config_get("alias.column")
            if alias_column.empty?
              table = "Aliases"
              column = "real_name"
              alias_column = "#{table}.#{column}"
              unless object_exist?(table)
                execute_command(:table_create,
                                :name => table,
                                :flags => "TABLE_HASH_KEY",
                                :key_type => "ShortText")
              end
              unless object_exist?(alias_column)
                execute_command(:column_create,
                                :table => table,
                                :name => column,
                                :flags => "COLUMN_SCALAR",
                                :type => "ShortText")
              end
              config_set("alias.column", alias_column)
            end
            alias_column
          end

          def recreate_index(full_index_name, alias_column)
            revision = generate_revision
            table_name, index_name = full_index_name.split(".", 2)
            real_index_name = "#{index_name}_#{revision}"
            real_full_index_name = "#{table_name}.#{real_index_name}"
            if object_exist?(full_index_name)
              set_alias(alias_column, full_index_name, real_full_index_name)
              column_rename(table_name, index_name, real_index_name)
              nil
            elsif object_exist?(real_full_index_name)
              nil
            else
              full_current_index_name =
                resolve_alias(alias_column, full_index_name)
              current_table_name, current_index_name =
                full_current_index_name.split(".", 2)
              if current_table_name != table_name
                abort_run("Different lexicon isn't supported: " +
                          "<#{full_index_name}> -> <#{full_current_index_name}>")
              end
              if current_index_name == real_index_name
                abort_run("Alias doesn't specify real index column: " +
                          "<#{full_current_index_name}>")
              end
              column_create_similar(table_name,
                                    real_index_name,
                                    current_index_name)
              set_alias(alias_column, full_index_name, real_full_index_name)
              full_current_index_name
            end
          end

          def remove_old_indexes(full_base_index_name, full_current_index_name)
            return if full_current_index_name.nil?

            table_name, base_index_name = full_base_index_name.split(".", 2)
            _, current_index_name = full_current_index_name.split(".", 2)

            target_index_columns = column_list(table_name).find_all do |column|
              column.name.start_with?("#{base_index_name}_") and
                column.index?
            end
            target_index_columns.collect(&:name).sort.each do |index_name|
              next unless /_(\d{4})(\d{2})(\d{2})\z/ =~ index_name
              next if index_name >= current_index_name
              column_remove(table_name, index_name)
            end
          end

          def generate_revision
            case @interval
            when :day
              @now.strftime("%Y%m%d")
            else
              abort_run("Unsupported revision: #{@interval}")
            end
          end
        end
      end
    end
  end
end
