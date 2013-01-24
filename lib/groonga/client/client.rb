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
require "groonga/client/client/gqtp"
require "groonga/client/client/http"

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

    attr_reader :protocol, :real_client

    def initialize(options)
      @protocol = options[:protocol] || :gqtp
      options.delete(:protocol)

      @real_client = nil
      if @protocol == :gqtp
        @real_client = Groonga::Client::GQTP.new(options)
      else
        @real_client = Groonga::Client::HTTP.new(options)
      end
    end

    def close
    end

    def cache_limit(parameters)
    end

    def check(parameters)
    end

    def clearlock(parameters)
    end

    def column_create(parameters)
    end

    def column_list(parameters)
    end

    def column_remove(parameters)
    end

    def column_rename(parameters)
    end

    def define_selector(parameters)
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
    end

    def table_remove(parameters)
    end

    def table_rename(parameters)
    end

    def truncate(parameters)
    end

    private
    def execute_command(command_name, parameters={})
      command = Groonga::Command::Base.new(command_name, parameters)
      Client::Command.new(command).execute(@real_client, @protocol)
    end
  end
end
