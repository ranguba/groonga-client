# Copyright (C) 2015-2020  Sutou Kouhei <kou@clear-code.com>
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

begin
  require "arrow"
rescue LoadError
end

require "groonga/command/parser"

require "groonga/client"
require "groonga/client/command-line/parser"

module Groonga
  class Client
    module CommandLine
      class GroongaClient
        def initialize
          @chunk = false
          @load_input_type = "json"
          @available_load_input_types = ["json"]
          if Object.const_defined?(:Arrow)
            @available_load_input_types << "apache-arrow"
          end
          @load_lock_table = false

          @runner_options = {
            :split_load_chunk_size => 10000,
            :generate_request_id   => false,
            :target_commands       => [],
            :target_tables         => [],
            :target_columns        => [],
          }
        end

        def run(arguments)
          parser = Parser.new
          command_file_paths = parser.parse(arguments) do |option_parser|
            parse_command_line(option_parser)
          end

          parser.open_client(:chunk => @chunk,
                             :load_input_type => @load_input_type,
                             :load_lock_table => @load_lock_table) do |client|
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
                runner.consume($stdin)
              end
            else
              command_file_paths.each do |command_file_path|
                runner.load(command_file_path)
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

          parser.on("--load-input-type=TYPE",
                    @available_load_input_types,
                    "Use TYPE as input type for load.",
                    "[#{@available_load_input_types.join(", ")}]",
                    "(#{@load_input_types})") do |type|
            @load_input_type = type
          end

          parser.on("--[no-]load-lock-table",
                    "Use lock_table=yes for load.",
                    "(#{@load_lock_table})") do |boolean|
            @load_lock_table = boolean
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

          parser.on("--target-command=COMMAND",
                    "Add COMMAND as target commands",
                    "You can specify multiple times",
                    "If COMMAND is /.../,",
                    "it's treated as a regular expression") do |command|
            add_target(@runner_options[:target_commands], command)
          end

          parser.on("--target-table=TABLE",
                    "Add TABLE as target tables",
                    "You can specify multiple times",
                    "If TABLE is /.../,",
                    "it's treated as a regular expression") do |table|
            add_target(@runner_options[:target_tables], table)
          end

          parser.on("--target-column=COLUMN",
                    "Add COLUMN as target columns",
                    "You can specify multiple times",
                    "If COLUMN is /.../,",
                    "it's treated as a regular expression") do |column|
            add_target(@runner_options[:target_columns], column)
          end
        end

        def add_target(targets, target)
          if /\A\\(.+?)\\(i)?\z/ =~ target
            pattern = Regexp.new($1, $2 == "i")
            targets << pattern
          else
            targets << target
          end
        end

        class Runner < CommandProcessor
          private
          def process_response(response, command)
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
