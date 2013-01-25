# -*- coding: utf-8 -*-
#
# Copyright (C) 2013  Haruka Yoshihara <yoshihara@clear-code.com>
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

    attr_reader :protocol, :protocol_name

    def initialize(options)
      @protocol_name = options[:protocol] || :gqtp
      options.delete(:protocol)

      @protocol = nil
      if @protocol_name == :gqtp
        options[:connection] ||= :synchronous
        @protocol = Groonga::Client::Protocol::GQTP.new(options)
      else
        @protocol = Groonga::Client::Protocol::HTTP.new(options)
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

    def define_selector(parameters)
      response = execute_command("define_selector", parameters)

      if response.header.first.zero?
        new_command_name = parameters[:name]
        Client.class_eval do
          define_method(new_command_name) do
            execute_command(new_command_name)
          end
        end
      end
      response
    end

    def defrag(parameters)
    end

    def delete(parameters)
    end

    def dump(parameters)
    end

    def load(parameters)
    end

    def log_level(parameters)
    end

    def log_put(parameters)
    end

    def log_reopen
    end

    def quit
    end

    def register(parameters)
    end

    def select(parameters)
    end

    def shutdown
    end

    def status
      execute_command("status")
    end

    def table_create(parameters)
    end

    def table_list
      execute_command("table_list")
    end

    def table_remove(parameters)
    end

    def table_rename(parameters)
    end

    def truncate(parameters)
    end

    private
    def execute_command(command_name, parameters={})
      parameters = normalize_parameters(parameters)
      command = Groonga::Command::Base.new(command_name, parameters)
      Client::Command.new(command).execute(@protocol, @protocol_name)
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
