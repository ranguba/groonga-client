# -*- coding: utf-8 -*-
#
# Copyright (C) 2013  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2013  Kouhei Sutou <kou@clear-code.com>
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

require "groonga/client/command"
require "groonga/client/protocol/gqtp"
require "groonga/client/protocol/http"

module Groonga
  class Client
    class << self
      def open(options={}, &block)
        client = new(options)
        if block_given?
          yield(client)
          client.close
        else
          client
        end
      end
    end

    attr_reader :protocol
    attr_reader :connection

    def initialize(options)
      @protocol = options.delete(:protocol) || :gqtp

      @connection = nil
      if @protocol == :gqtp
        @connection = Groonga::Client::Protocol::GQTP.new(options)
      else
        @connection = Groonga::Client::Protocol::HTTP.new(options)
      end
    end

    def close
    end

    def cache_limit(parameters)
      execute_command("cache_limit", parameters)
    end

    def check(parameters)
      execute_command("check", parameters)
    end

    def clearlock(parameters={})
      execute_command("clearlock", parameters)
    end

    def column_create(parameters)
      execute_command("column_create", parameters)
    end

    def column_list(parameters)
      execute_command("column_list", parameters)
    end

    def column_remove(parameters)
      execute_command("column_remove", parameters)
    end

    def column_rename(parameters)
      execute_command("column_rename", parameters)
    end

    def defrag(parameters={})
      execute_command("defrag", parameters)
    end

    def delete(parameters)
      execute_command("delete", parameters)
    end

    def dump(parameters={})
      execute_command("dump", parameters)
    end

    def load(parameters)
      execute_command("load", parameters)
    end

    def log_level(parameters)
      execute_command("log_level", parameters)
    end

    def log_put(parameters)
      execute_command("log_put", parameters)
    end

    def log_reopen(parameters={})
      execute_command("log_reopen", parameters)
    end

    def quit(parameters={})
      execute_command("quit", parameters)
    end

    def register(parameters)
      execute_command("register", parameters)
    end

    def select(parameters)
    end

    def shutdown(parameters={})
    end

    def status(parameters={})
      execute_command("status", parameters)
    end

    def table_create(parameters)
    end

    def table_list(parameters={})
      execute_command("table_list", parameters)
    end

    def table_remove(parameters)
    end

    def table_rename(parameters)
    end

    def truncate(parameters)
    end

    def execute(command, &block)
      Client::Command.new(command).execute(@connection, &block)
    end

    private
    def execute_command(command_name, parameters={})
      parameters = normalize_parameters(parameters)
      command_class = Groonga::Command.find(command_name)
      command = command_class.new(command_name, parameters)
      execute(command)
    end

    def normalize_parameters(parameters)
      normalized_parameters = {}
      parameters.each do |key, value|
        normalized_parameters[key] = value.to_s
      end
      normalized_parameters
    end
  end
end
