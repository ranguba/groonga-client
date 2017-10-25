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

require "optparse"
require "json"

require "groonga/client"

module Groonga
  class Client
    module CommandLine
      class GroongaClientIndexRecreate
        def initialize
          @url      = nil
          @protocol = :http
          @host     = "localhost"
          @port     = nil

          @read_timeout = -1

          @n_workers = 0
        end

        def run(argv)
          target_indexes = parse_command_line(argv)

          Client.open(:url      => @url,
                      :protocol => @protocol,
                      :host     => @host,
                      :port     => @port,
                      :read_timeout => @read_timeout,
                      :backend  => :synchronous) do |client|
            runner = Runner.new(client, target_indexes)
            runner.run do
              @n_workers.times do
                client.database_unmap
              end
            end
          end
        end

        private
        def parse_command_line(argv)
          parser = OptionParser.new
          parser.version = VERSION
          parser.banner += " LEXICON1.INDEX1 LEXICON2.INDEX2 ..."

          parser.separator("")

          parser.separator("Connection:")

          parser.on("--url=URL",
                    "URL to connect to Groonga server.",
                    "If this option is specified,",
                    "--protocol, --host and --port are ignored.") do |url|
            @url = url
          end

          available_protocols = [:http, :gqtp]
          parser.on("--protocol=PROTOCOL", [:http, :gqtp],
                    "Protocol to connect to Groonga server.",
                    "[#{available_protocols.join(", ")}]",
                    "(#{@protocol})") do |protocol|
            @protocol = protocol
          end

          parser.on("--host=HOST",
                    "Groonga server to be connected.",
                    "(#{@host})") do |host|
            @host = host
          end

          parser.on("--port=PORT", Integer,
                    "Port number of Groonga server to be connected.",
                    "(auto)") do |port|
            @port = port
          end

          parser.on("--read-timeout=TIMEOUT", Integer,
                    "Timeout on reading response from Groonga server.",
                    "You can disable timeout by specifying -1.",
                    "(#{@read_timeout})") do |timeout|
            @read_timeout = timeout
          end

          parser.on("--n-workers=N", Integer,
                    "The number of groonga-httpd workers.",
                    "This options is meaningless for groonga -s.",
                    "(#{@n_workers})") do |n|
            @n_workers = n
          end

          target_indexes = parser.parse(argv)

          @port ||= default_port(@protocol)

          target_indexes
        end

        def default_port(protocol)
          case protocol
          when :http
            10041
          when :gqtp
            10043
          end
        end

        class Runner
          def initialize(client, target_indexes)
            @client = client
            @target_indexes = target_indexes
          end

          def run
            catch do |tag|
              @abort_tag = tag
              alias_column = ensure_alias_column
              @target_indexes.each do |index|
                current_index = recreate_index(index, alias_column)
                remove_old_indexes(index, current_index)
              end
              yield if block_given?
              true
            end
          end

          private
          def execute_command(name, arguments={})
            response = @client.execute(name, arguments)
            unless response.success?
              puts("failed to run #{name}: #{response.inspect}")
              throw(@abort_tag, false)
            end
            response
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
            # TODO: check return value
            execute_command(:load,
                            :table => table,
                            :values => JSON.generate(values))
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
            revision = Time.now.strftime("%Y%m%d")
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
                puts("!!!")
              end
              if current_index_name == real_index_name
                puts("Same")
                return nil
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
        end
      end
    end
  end
end
