# Copyright (C) 2015-2021  Sutou Kouhei <kou@clear-code.com>
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

require "groonga/command/parser"

module Groonga
  class Client
    class CommandProcessor
      def initialize(client, options={})
        @client = client
        @split_load_chunk_size = options[:split_load_chunk_size] || 10000
        @generate_request_id   = options[:generate_request_id]
        @target_commands       = options[:target_commands] || []
        @target_tables         = options[:target_tables] || []
        @target_columns        = options[:target_columns] || []
        @load_values = []
        @parser = create_command_parser
      end

      def <<(line)
        @parser << line
      end

      def finish
        @parser.finish
      end

      def consume(input)
        last_line = nil
        input.each_line do |line|
          last_line = line
          @parser << line
        end
        if last_line and not last_line.end_with?("\n")
          @parser << "\n"
        end
      end

      def load(path)
        File.open(path) do |input|
          consume(input)
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
        return unless target_command?(command)
        return unless target_table?(command)
        return unless target_column?(command)

        command = Marshal.load(Marshal.dump(command))
        apply_target_columns(command)
        command[:request_id] ||= SecureRandom.uuid if @generate_request_id
        response = @client.execute(command)
        process_response(response, command)
      end

      def process_response(response, command)
      end

      def target_command?(command)
        return true if @target_commands.empty?

        @target_commands.any? do |name|
          name === command.command_name
        end
      end

      def target_table?(command)
        return true if @target_tables.empty?

        target = nil
        case command.command_name
        when "load", "column_create", "select"
          target = command.table
        when "table_create", "table_remove"
          target = command.name
        end
        return true if target.nil?

        @target_tables.any? do |name|
          name === target
        end
      end

      def target_column?(command)
        return true if @target_columns.empty?

        target = nil
        case command.command_name
        when "column_create"
          target = command.name
        end
        return true if target.nil?

        @target_columns.any? do |name|
          name === target
        end
      end

      def apply_target_columns(command)
        return if @target_columns.empty?

        values = command[:values]
        return if values.nil?

        command = command.dup

        values = JSON.parse(values)
        columns = command[:columns]
        if columns
          columns = columns.split(/\s*,\s*/)
          target_indexes = []
          new_columns = []
          columns.each_with_index do |column, i|
            if load_target_column?(column)
              target_indexes << i
              new_columns << column
            end
          end
          command[:columns] = new_columns.join(",")
          new_values = values.collect do |value|
            target_indexes.collect do |i|
              value[i]
            end
          end
          command[:values] = JSON.generate(new_values)
        else
          new_values = values.collect do |value|
            new_value = {}
            value.each do |key, value|
              if load_target_column?(key)
                new_value[key] = value
              end
            end
            new_value
          end
          command[:values] = JSON.generate(new_values)
        end
      end

      def load_target_column?(column)
        column == "_key" or
          @target_columns.any? {|name| name === column}
      end
    end
  end
end
