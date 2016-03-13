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

require "groonga/client/version"
require "groonga/client/protocol/error"

module Groonga
  class Client
    module Protocol
      class HTTP
        class UnknownBackendError < Error
          attr_reader :backend
          def initialize(backend, detail)
            @backend = backend
            super("Unknown HTTP backend: <#{backend}>: #{detail}")
          end
        end

        def initialize(url, options)
          @url = url
          @options = default_options.merge(options)
          @backend = create_backend
        end

        def send(command, &block)
          @backend.send(command, &block)
        end

        def connected?
          @backend.connected?
        end

        def close(&block)
          @backend.close(&block)
        end

        private
        def default_options
          {
            :user_agent => "groonga-client/#{VERSION}",
          }
        end

        def create_backend
          backend = @options[:backend] || :thread

          begin
            require "groonga/client/protocol/http/#{backend}"
          rescue LoadError
            raise UnknownBackendError.new(backend, $!.message)
          end

          backend_name = backend.to_s.capitalize
          backend_class = self.class.const_get(backend_name)
          backend_class.new(@url, @options)
        end
      end
    end
  end
end
