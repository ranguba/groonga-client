# Copyright (C) 2015-2016  Kouhei Sutou <kou@clear-code.com>
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

require "optparse"

require "groonga/client"

module Groonga
  class Client
    module CommandLine
      class GroongaClientIndexCheck
        def initialize
          @url      = nil
          @protocol = :http
          @host     = "localhost"
          @port     = 10041
          @check_missing_source = false
          @check_index_integrity = false
          @target = false
        end

        def run(argv)
          @target = parse_command_line(argv)

          @client = Client.new(:url      => @url,
                               :protocol => @protocol,
                               :host     => @host,
                               :port     => @port,
                               :backend  => :synchronous)
          options = {
            :check_missing_source => @check_missing_source,
            :check_index_integrity => @check_index_integrity,
            :target => @target
          }
          checker = Checker.new(@client, options)
          checker.check
        end

        private
        def parse_command_line(argv)
          parser = OptionParser.new
          parser.version = VERSION
          parser.banner += " LEXICON1.INDEX LEXICON2.INDEX2 ..."

          parser.separator("")

          parser.separator("Mode:")

          parser.on("--check-missing-source",
                    "Check whether there is an index column which lacks index source.",
                    "(false)") do
            @check_missing_source = true
          end

          parser.on("--check-index-integrity",
                    "Check whether there is a broken index column.",
                    "(false)") do
            @check_index_integrity = true
          end

          parser.separator("Connection:")

          parser.on("--url=URL",
                    "URL to connect to Groonga server.",
                    "If this option is specified,",
                    "--protocol, --host and --port are ignored.") do |url|
            @url = url
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

          parser.parse(argv)
        end

        class Checker
          def initialize(client, options)
            @client = client
            @options = options
            @exit_code = 0
          end

          def check
            succeeded = 1
            catch(:fail) do
              if @options[:check_missing_source]
                succeeded = check_missing_source
              end
              if @options[:check_index_integrity]
                succeeded = check_index_integrity
              end
            end
            succeeded
          end

          def abort_run(message)
            $stderr.puts(message)
            throw(:fail, false)
          end

          def execute_command(name, arguments={})
            response = @client.execute(name, arguments)
            unless response.success?
              abort_run("Failed to run #{name}: #{response.inspect}")
            end
            response
          end

          def table_list
            execute_command(:table_list)
          end

          def column_list(table_name)
            execute_command(:column_list,
                            :table => table_name)
          end

          def column_create(table_name, name, flags, type, source)
            execute_command(:column_create,
                            :table => table_name,
                            :name => name,
                            :flags => flags,
                            :type => type,
                            :source => source)
          end

          def column_remove(table_name, column_name)
            execute_command(:column_remove,
                            :table => table_name,
                            :name => column_name)
          end

          def check_target_table?(table_name)
            unless @options[:target].count > 0
              return true
            end
            if @options[:target].kind_of?(Array)
              @options[:target].each do |name|
                table_part = name.split(".").first
                return true if table_name == table_part
              end
            end
            false
          end

          def check_target_column?(column)
            unless @options[:target].count > 0
              return column["type"] == "index"
            else
              unless column["type"] == "index"
                return false
              end
            end
            if @options[:target].kind_of?(Array)
              @options[:target].each do |name|
                return true if name == "#{column['domain']}.#{column['name']}" or
                  name == column["domain"]
              end
            end
            false
          end

          def missing_source?(column)
            column["type"] == "index" and column["source"].empty?
          end

          def check_missing_source
            missing_index_names = []
            table_list.each do |table|
              unless check_target_table?(table["name"])
                next
              end
              column_list(table["name"]).each do |column|
                unless check_target_column?(column)
                  next
                end
                if missing_source?(column)
                  missing_index_names << "#{column['domain']}.#{column['name']}"
                end
              end
            end
            missing_index_names.each do |column|
              puts "index column:<#{column}> is missing source."
            end
            missing_index_names.count
          end

          def list_tokens(table_name)
            keys = []
            response = execute_command(:select,
                                       :table => table_name,
                                       :limit => -1,
                                       :output_columns => :_key)
            keys = response.records.collect do |record|
              record["_key"]
            end
            keys
          end

          def verify_tokens(table_name, old_column, new_column, tokens)
            broken_index_tokens = []
            tokens.each do |token|
              query = Groonga::Client::ScriptSyntax.format_string(token)
              old_response = execute_command(:select,
                                             :table => table_name,
                                             :match_columns => old_column,
                                             :query => query,
                                             :output_columns => :_id,
                                             :limit => -1,
                                             :sort_keys => :_id)
              new_response = execute_command(:select,
                                             :table => table_name,
                                             :match_columns => new_column,
                                             :query => query,
                                             :output_columns => :_id,
                                             :limit => -1,
                                             :sort_keys => :_id)
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

          def check_index_integrity
            table_names = table_list.collect do |table|
              if check_target_table?(table["name"])
                table["name"]
              end
            end.compact
            target_columns = []
            table_names.each do |table_name|
              column_list(table_name).collect do |column|
                if check_target_column?(column)
                  target_columns << column
                end
              end
            end
            if target_columns.empty?
              @exit_code = 1
              abort_run("Failed to check <#{@options[:target].join(',')}> because there is no such a LEXCON.INDEX.")
            end
            broken_indexes = []
            target_columns.each do |column|
              table_name = column["domain"]
              column_name = column["name"]
              suffix = Time.now.strftime("%Y%m%d%H%M%S_%N")
              new_column_name = "#{column_name}_#{suffix}"
              if column["source"].empty?
                puts("Failed to check <#{column['domain']}.#{column['name']}> because of missing source.")
                next
              end
              type, source = column["source"].first.split(".")
              flags = column["flags"].sub(/\|PERSISTENT/, '')
              column_create(table_name,
                            new_column_name,
                            flags,
                            type,
                            source)
              tokens = list_tokens(table_name)
              puts "check #{tokens.count} tokens against <#{table_name}.#{column_name}>."
              broken_index_tokens = verify_tokens(table_name, column_name,
                                                  new_column_name, tokens)
              column_remove(table_name, new_column_name)
              if broken_index_tokens.count > 0
                broken_indexes << "#{table_name}.#{column_name}"
              end
            end
            broken_indexes.each do |index_column|
              puts "<#{index_column}> is broken."
            end
            broken_indexes.count
          end
        end
      end
    end
  end
end
