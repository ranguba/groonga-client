# Copyright (C) 2015  Kouhei Sutou <kou@clear-code.com>
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

require "ostruct"
require "optparse"
require "json"

require "groonga/command/parser"

require "groonga/client"

module Groonga
  class Client
    module CommandLine
      class GroongaClient
        def initialize
          @protocol = :http
          @host     = "localhost"
          @port     = nil

          @runner_options = {
            :split_load_chunk_size => 10000,
          }
        end

        def run(argv)
          command_file_paths = parse_command_line(argv)

          @client = Groonga::Client.new(:protocol => @protocol,
                                        :host     => @host,
                                        :port     => @port,
                                        :backend  => :synchronous)
          runner = Runner.new(@client, @runner_options)

          if command_file_paths.empty?
            $stdin.each_line do |line|
              runner << line
            end
          else
            command_file_paths.each do |command_file_path|
              File.open(command_file_path) do |command_file|
                command_file.each_line do |line|
                  runner << line
                end
              end
            end
          end

          true
        end

        private
        def parse_command_line(argv)
          parser = OptionParser.new
          parser.version = VERSION
          parser.banner += " GROONGA_COMMAND_FILE1 GROONGA_COMMAND_FILE2 ..."

          parser.separator("")

          parser.separator("Connection:")

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

          parser.on("--split-load-chunk-size=SIZE", Integer,
                    "Split a large load to small loads.",
                    "Each small load has at most SIZE records.",
                    "Set 0 to SIZE to disable this feature.",
                    "(#{@runner_options[:split_load_chunk_size]})") do |size|
            @runner_options[:split_load_chunk_size] = size
          end

          command_file_paths = parser.parse(argv)

          @port ||= default_port(@protocol)

          command_file_paths
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
          def initialize(client, options={})
            @client = client
            @split_load_chunk_size = options[:split_load_chunk_size] || 10000
            @load_values = []
            @parser = create_command_parser
          end

          def <<(line)
            @parser << line
          end

          private
          def create_command_parser
            parser = Groonga::Command::Parser.new

            parser.on_command do |command|
              run_command(command)
            end

            parser.on_load_columns do |command, columns|
              command[:columns] ||= columns.join(",")
            end

            parser.on_load_value do |command, value|
              unless command[:values]
                @load_values << value
                if @load_values.size == @split_load_chunk_size
                  consume_load_values(command)
                end
              end
              command.original_source.clear
            end

            parser.on_load_complete do |command|
              if command[:values]
                run_command(client, command)
              else
                consume_load_values(command)
              end
            end

            parser
          end

          def consume_load_values(load_command)
            return if @load_values.empty?

            load_command[:values] = Yajl::Encoder.encode(@load_values)
            run_command(load_command)
            @load_values.clear
            load_command[:values] = nil
          end

          def run_command(command)
            response = @client.execute(command)
            case command.output_type
            when :json
              puts(JSON.pretty_generate([response.header, response.body]))
            when :xml
              puts(response.raw)
            else
              puts(response.body)
            end
          end
        end
      end
    end
  end
end
