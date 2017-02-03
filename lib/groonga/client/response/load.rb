# Copyright (C) 2013  Haruka Yoshihara <yoshihara@clear-code.com>
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

require "groonga/client/response/base"

module Groonga
  class Client
    module Response
      class Load < Base
        Response.register("load", self)

        # @return [Integer] The number of loaded records.
        #
        # @since 0.3.2
        attr_accessor :n_loaded_records

        # @return [::Array<Integer>] The IDs of loaded records. ID is
        #   `0` if the corresponding record is failed to add.
        #
        #   If you don't specify `yes` to `output_ids` `load`
        #   parameter, this is always an empty array.
        #
        # @since 0.3.3
        attr_accessor :loaded_ids

        # @return [::Array<Groonga::Client::Response::Load::Error>]
        #   The errors of loaded records. `error.return_code` isn't
        #   `0` if the corresponding record is failed to load.
        #
        #   If you don't specify `yes` to `output_errors` `load`
        #   parameter, this is always an empty array.
        #
        # @since 0.4.1
        attr_accessor :errors

        def body=(body)
          super(body)
          parse_body(body)
        end

        private
        def parse_body(body)
          if body.is_a?(::Hash)
            @n_loaded_records = body["n_loaded_records"]
            @loaded_ids = body["loaded_ids"] || []
            @errors = (body["errors"] || []).collect do |error|
              Error.new(error["return_code"] || 0,
                        error["message"])
            end
          else
            @n_loaded_records = body
            @loaded_ids = []
            @errors = []
          end
        end

        class Error < Struct.new(:return_code, :message)
        end
      end
    end
  end
end
