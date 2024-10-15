# Copyright (C) 2014  Kouhei Sutou <kou@clear-code.com>
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

require "groonga/client/response/base"

module Groonga
  class Client
    module Response
      class Error < Base
        # @return [String, nil] The error message of the error response.
        #
        # @since 0.1.0
        def message
          error_message
        end

        # @return [String, nil] The function name where the error is occurred.
        #
        # @since 0.5.9
        def function
          if header.nil?
            nil
          elsif header_v1?
            header[4]
          else
            (header["error"] || {})["function"]
          end
        end

        # @return [String, nil] The file name where the error is occurred.
        #
        # @since 0.5.9
        def file
          if header.nil?
            nil
          elsif header_v1?
            header[5]
          else
            (header["error"] || {})["file"]
          end
        end

        # @return [String, nil] The line where the error is occurred.
        #
        # @since 0.5.9
        def line
          if header.nil?
            nil
          elsif header_v1?
            header[5]
          else
            (header["error"] || {})["line"]
          end
        end
      end
    end
  end
end

