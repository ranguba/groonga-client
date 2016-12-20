# Copyright (C) 2016  Kouhei Sutou <kou@clear-code.com>
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

require "rbconfig"
require "fileutils"

require "groonga/command/parser"

module Groonga
  class Client
    module Test
      class GroongaServerRunner
        def initialize
          @pid = nil
          @using_running_server = false
          @groonga = find_groonga
          @tmp_dir = nil
        end

        def run
          if groonga_server_running?
            @using_running_server = true
            @dump = open_client do |client|
              client.dump.body
            end
          else
            return if @groonga.nil?
            @tmp_dir = create_tmp_dir
            db_path = @tmp_dir + "db"
            @pid = spawn(@groonga,
                         "--port", url.port.to_s,
                         "--log-path", (@tmp_dir + "groonga.log").to_s,
                         "--query-log-path", (@tmp_dir + "query.log").to_s,
                         "--protocol", "http",
                         "-s",
                         "-n", db_path.to_s)
            wait_groonga_ready
          end
        end

        def stop
          if @using_running_server
            open_client do |client|
              remove_all(client)
              restore(client)
            end
          else
            if @pid
              open_client do |client|
                client.shutdown
              end
              wait_groonga_shutdown
            end
            if @tmp_dir
              FileUtils.rm_rf(@tmp_dir)
            end
          end
        end

        def using_running_server?
          @using_running_server
        end

        def url
          @url ||= build_url
        end

        private
        def open_client(&block)
          Client.open(url: url, &block)
        end

        def build_url
          default_options = Groonga::Client.default_options
          url = default_options[:url]
          if url.nil?
            host = default_options[:host] ||
              default_options[:address] ||
              "127.0.0.1"
            port = default_options[:port] || 10041
            path = default_options[:path]
            url = URI("http://#{host}:#{port}#{path}")
          end
          url
        end

        def groonga_server_running?
          begin
            TCPSocket.open(url.host, url.port) do
            end
          rescue SystemCallError
            false
          else
            true
          end
        end

        def find_groonga
          paths = ENV["PATH"].split(File::PATH_SEPARATOR)
          exeext = RbConfig::CONFIG["EXEEXT"]
          paths.each do |path|
            groonga = File.join(path, "groonga#{exeext}")
            return groonga if File.executable?(groonga)
          end
          nil
        end

        def create_tmp_dir
          tmpfs_dir = "/dev/shm"
          if File.directory?(tmpfs_dir)
            base_tmp_dir = Pathname(tmpfs_dir)
          else
            base_tmp_dir = Pathname("tmp")
          end
          tmp_dir = base_tmp_dir + "groonga-client.#{Process.pid}"
          FileUtils.rm_rf(tmp_dir)
          FileUtils.mkdir_p(tmp_dir)
          tmp_dir
        end

        def wait_groonga_ready
          n_retried = 0
          while n_retried <= 20
            n_retried += 1
            sleep(0.05)
            if groonga_server_running?
              break
            else
              begin
                pid = Process.waitpid(@pid, Process::WNOHANG)
              rescue SystemCallError
                @pid = nil
                break
              end
            end
          end
        end

        def wait_groonga_shutdown
          # TODO: Remove me when Groonga 6.0.1 has been released.
          # Workaround to shutdown as soon as possible.
          groonga_server_running?

          n_retried = 0
          while n_retried <= 20
            n_retried += 1
            sleep(0.05)
            pid = Process.waitpid(@pid, Process::WNOHANG)
            return if pid
          end

          Process.kill(:KILL, @pid)
          Process.waitpid(@pid)
        end

        def remove_all(client)
          schema = client.schema
          schema.tables.each_value do |table|
            table.columns.each_value do |column|
              client.column_remove(:table => table.name,
                                   :name => column.name)
            end
          end
          schema.tables.each_value do |table|
            client.table_remove(:name => table.name)
          end
          schema.plugins.each_value do |plugin|
            client.plugin_unregister(:name => plugin.name)
          end
        end

        def restore(client)
          return if @dump.empty?

          parser = Groonga::Command::Parser.new

          parser.on_command do |command|
            client.execute(command)
          end

          parser.on_load_columns do |command, columns|
            command[:columns] ||= columns.join(",")
          end

          load_values = []
          parser.on_load_value do |command, value|
            unless command[:values]
              load_values << value
            end
            command.original_source.clear
          end

          parser.on_load_complete do |command|
            unless command[:values]
              command[:values] = JSON.generate(load_values)
              load_values.clear
            end
            client.execute(command)
          end

          @dump.each_line do |line|
            parser << line
          end
          parser.finish
        end
      end
    end
  end
end
