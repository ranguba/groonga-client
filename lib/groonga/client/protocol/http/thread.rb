# Copyright (C) 2013  Haruka Yoshihara <yoshihara@clear-code.com>
# Copyright (C) 2013-2014  Kouhei Sutou <kou@clear-code.com>
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

require "thread"

require "groonga/client/protocol/http/synchronous"

module Groonga
  class Client
    module Protocol
      class HTTP
        class Thread < Synchronous
          class Request
            def initialize(thread)
              @thread = thread
            end

            def wait
              @thread.join
            end
          end

          def send(command)
            thread = ::Thread.new do
              super
            end
            Request.new(thread)
          end
        end
      end
    end
  end
end
