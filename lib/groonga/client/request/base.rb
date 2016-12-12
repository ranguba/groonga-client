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

module Groonga
  class Client
    module Request
      class Base
        def initialize(parameters=nil, extensions=[])
          @parameters = parameters
          @extensions = extensions
          extend(*@extensions) unless @extensions.empty?
        end

        def response
          @reponse ||= create_response
        end

        def parameter(name, value)
          add_parameter(OverwriteMerger,
                        RequestParameter.new(name, value))
        end

        def to_parameters
          if @parameters.nil?
            {}
          else
            @parameters.to_parameters
          end
        end

        def extensions(*modules, &block)
          modules << Module.new(&block) if block
          if modules.empty?
            self
          else
            create_request(@parameters, @extensions | modules)
          end
        end

        private
        def add_parameter(merger_class, parameter)
          merger = merger_class.new(@parameters, parameter)
          create_request(merger, @extensions)
        end

        def create_request(parameters, extensions)
          self.class.new(parameters, extensions)
        end

        def create_response
          open_client do |client|
            response = client.execute(self.class.command_name, to_parameters)
            raise ErrorResponse.new(response) unless response.success?
            response
          end
        end

        def open_client
          Client.open do |client|
            yield(client)
          end
        end
      end

      class RequestParameter
        def initialize(name, value)
          @name = name
          @value = value
        end

        def to_parameters
          {
            @name => @value,
          }
        end
      end

      class ParameterMerger
        def initialize(parameters1, parameters2)
          @parameters1 = parameters1
          @parameters2 = parameters2
        end
      end

      class OverwriteMerger < ParameterMerger
        def to_parameters
          @parameters1.to_parameters.merge(@parameters2.to_parameters)
        end
      end
    end
  end
end
