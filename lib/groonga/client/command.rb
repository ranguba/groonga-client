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

require "groonga/command"
require "groonga/client/response"

module Groonga
  class Client
    class Command
      def initialize(command)
        @command = command
      end

      def execute(connection)
        async = block_given?

        response = nil
        request = connection.send(@command) do |raw_response|
          response = parse_raw_response(raw_response)
          yield(response) if async
        end

        if async
          request
        else
          request.wait
          response
        end
      end

      private
      def parse_raw_response(raw_response)
        response_class = Groonga::Client::Response.find(@command.name)
        response_class.parse(raw_response, @command.output_type)
      end
    end
  end
end
