# Copyright (C) 2015-2017  Kouhei Sutou <kou@clear-code.com>
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
require "securerandom"

require "groonga/client"

require "groonga/command/parser"

module Groonga
  class Client
    module CommandLine
      class GroongaClient
        def initialize
          @protocol = :http
          @host     = "localhost"
          @port     = nil

          @read_timeout = Client::Default::READ_TIMEOUT

          @chunk = false

          @runner_options = {
            :split_load_chunk_size => 10000,
            :generate_request_id   => false,
          }
        end

        def run(argv)
          command_file_paths = parse_command_line(argv)

          @client = Client.new(:protocol => @protocol,
                               :host     => @host,
                               :port     => @port,
                               :read_timeout => @read_timeout,
                               :chunk    => @chunk,
                               :backend  => :synchronous)
          runner = Runner.new(@client, @runner_options)

          if command_file_paths.empty?
            $stdin.each_line do |line|
              runner << line
            end
          else
            command_file_paths.each do |command_file_path|
              File.open(command_file_path) do |command_file|
                last_line = nil
                command_file.each_line do |line|
                  last_line = line
                  runner << line
                end
                if last_line and !last_line.end_with?("\n")
                  runner << "\n"
                end
              end
            end
          end
          runner.finish

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

          parser.on("--read-timeout=TIMEOUT", Integer,
                    "Timeout on reading response from Groonga server.",
                    "You can disable timeout by specifying -1.",
                    "(#{@read_timeout})") do |timeout|
            @read_timeout = timeout
          end

          parser.on("--split-load-chunk-size=SIZE", Integer,
                    "Split a large load to small loads.",
                    "Each small load has at most SIZE records.",
                    "Set 0 to SIZE to disable this feature.",
                    "(#{@runner_options[:split_load_chunk_size]})") do |size|
            @runner_options[:split_load_chunk_size] = size
          end

          parser.on("--[no-]generate-request-id",
                    "Add auto generated request ID to all commands.",
                    "(#{@runner_options[:generate_request_id]})") do |boolean|
            @runner_options[:generate_request_id] = boolean
          end

          parser.on("--[no-]chunk",
                    "Use \"Transfer-Encoding: chunked\" for load command.",
                    "HTTP only.",
                    "(#{@chunk})") do |boolean|
            @chunk = boolean
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
            @generate_request_id   = options[:generate_request_id]
            @load_values = []
            @parser = create_command_parser
          end

          def <<(line)
            @parser << line
          end

          def finish
            @parser.finish
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
                run_command(command)
              else
                consume_load_values(command)
              end
            end

            parser
          end

          def consume_load_values(load_command)
            return if @load_values.empty?

            values_json = "["
            @load_values.each_with_index do |value, i|
              values_json << "," unless i.zero?
              values_json << "\n"
              values_json << JSON.generate(value)
            end
            values_json << "\n]\n"
            load_command[:values] = values_json
            run_command(load_command)
            @load_values.clear
            load_command[:values] = nil
          end

          def run_command(command)
            command[:request_id] ||= SecureRandom.uuid if @generate_request_id
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
