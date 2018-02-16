# Copyright (C) 2015-2018  Kouhei Sutou <kou@clear-code.com>
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

require "fileutils"
require "json"
require "pathname"
require "securerandom"

require "groonga/command/parser"

require "groonga/client"
require "groonga/client/command-line/parser"

module Groonga
  class Client
    module CommandLine
      class GroongaClient
        def initialize
          @chunk = false

          @runner_options = {
            :split_load_chunk_size => 10000,
            :generate_request_id   => false,
          }
        end

        def run(arguments)
          parser = Parser.new
          command_file_paths = parser.parse(arguments) do |option_parser|
            parse_command_line(option_parser)
          end

          parser.open_client(:chunk => @chunk) do |client|
            runner = Runner.new(client, @runner_options)

            if command_file_paths.empty?
              if $stdin.tty? and $stdout.tty?
                begin
                  require "readline"
                rescue LoadError
                  repl = BareREPL.new(runner)
                else
                  repl = ReadlineREPL.new(runner)
                end
                repl.run
              else
                $stdin.each_line do |line|
                  runner << line
                end
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
          end

          true
        end

        private
        def parse_command_line(parser)
          parser.banner += " GROONGA_COMMAND_FILE1 GROONGA_COMMAND_FILE2 ..."

          parser.separator("")
          parser.separator("Request:")

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

          def repl
            begin
              require "readline"
            rescue LoadError
              repl = BareREPL.new(self)
            else
              repl = ReadlineREPL.new(self)
              repl_readline
            end
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

        class BareREPL
          def initialize(runner)
            @runner = runner
          end

          def run
            loop do
              print("> ")
              $stdout.flush
              line = gets
              break if line.nil?
              @runner << line
            end
          end
        end

        class ReadlineREPL
          def initialize(runner)
            @runner = runner
            @history_path = guess_history_path
            read_history
          end

          def run
            loop do
              line = Readline.readline("> ", true)
              break if line.nil?
              add_history(line)
              @runner << line
              @runner << "\n"
            end
          end

          private
          def guess_history_path
            case RUBY_PLATFORM
            when /mswin/, /mingw/
              base_dir = ENV["LOCALAPPDATA"] || "~/AppData"
            when /darwin/
              base_dir = "~/Library/Preferences"
            else
              base_dir = ENV["XDG_CONFIG_HOME"] || "~/.config"
            end
            Pathname(base_dir).expand_path + "groonga-client" + "history.txt"
          end

          def read_history
            if @history_path.exist?
              @history_path.open do |history_file|
                history_file.each_line do |line|
                  Readline::HISTORY << line.chomp
                end
              end
              @history_timestamp = @history_path.mtime
            else
              @history_timestamp = Time.now
            end
          end

          def add_history(entry)
            updated = history_is_updated?

            if new_history_entry?(entry)
              FileUtils.mkdir_p(@history_path.dirname)
              @history_path.open("a") do |history_file|
                history_file << entry
                history_file << "\n"
              end
            else
              Readline::HISTORY.pop
            end

            if updated
              Readline::HISTORY.clear
              read_history
            end
          end

          def history_is_updated?
            @history_path.exist? and
              @history_path.mtime > @history_timestamp
          end

          def new_history_entry?(entry)
            return false if /\A\s*\z/ =~ entry
            if Readline::HISTORY.size > 1 and Readline::HISTORY[-2] == entry
              return false
            end
            true
          end
        end
      end
    end
  end
end
