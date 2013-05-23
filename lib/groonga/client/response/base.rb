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

require "json"

module Groonga
  class Client
    module Response
      class << self
        @@registered_commands = {}
        def register(name, klass)
          @@registered_commands[name] = klass
        end

        def find(name)
          @@registered_commands[name] || Base
        end
      end

      class Base
        class << self
          def parse(response, type)
            case type
            when :json
              header, body = JSON.parse(response)
            else
              header = nil
              body = response
            end
            new(header, body)
          end
        end

        attr_accessor :header, :body

        def initialize(header, body)
          @header = header
          @body = body
        end
      end
    end
  end
end
