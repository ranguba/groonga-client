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

module Groonga
  class Client
    module CommandLine
      class Runner
        def initialize(client)
          @client = client
        end

        def run(&block)
          catch do |tag|
            @abort_tag = tag
            run_internal(&block)
          end
        end

        private
        def abort_run(message)
          $stderr.puts(message)
          throw(@abort_tag, false)
        end

        def execute_command(name, arguments={})
          response = @client.execute(name, arguments)
          unless response.success?
            abort_run("Failed to run #{name}: #{response.inspect}")
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

        def table_list
          execute_command(:table_list)
        end

        def column_list(table)
          execute_command(:column_list, :table => table)
        end

        def column_create(table_name, name, flags, type, source)
          execute_command(:column_create,
                          :table => table_name,
                          :name => name,
                          :flags => flags,
                          :type => type,
                          :source => source).body
        end

        def column_create_similar(table_name, column_name, base_column_name)
          if object_exist?(:schema)
            info = execute_command(:schema)["#{table_name}.#{base_column_name}"]
            arguments = info.command.arguments.merge("name" => column_name)
            # For workaround Groonga < 7.0.6
            if arguments.key?("sources")
              arguments["source"] = arguments["sources"]
            end
            execute_command(:column_create, arguments).body
          else
            base_column = column_list(table_name).find do |column|
              column.name == base_column_name
            end
            range = base_column.range
            source_columns = base_column.sources.collect do |source|
              if source.include?(".")
                source.split(".", 2)[1]
              else
                "_key"
              end
            end
            flags = base_column.flags.dup
            flags.delete("PERSISTENT")
            column_create(table_name,
                          column_name,
                          flags.join("|"),
                          range,
                          source_columns.join(","))
          end
        end

        def column_remove(table, column)
          execute_command(:column_remove,
                          :table => table,
                          :name => column).body
        end

        def column_rename(table, name, new_name)
          execute_command(:column_rename,
                          :table => table,
                          :name => name,
                          :new_name => new_name).body
        end

        def select(table, arguments={})
          execute_command(:select,
                          arguments.merge(:table => table))
        end
      end
    end
  end
end
