# -*- coding: utf-8 -*-
#
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

require "rexml/document"
require "json"

require "hashie"

module Groonga
  class Client
    module Response
      class << self
        @@registered_commands = {}
        def register(name, klass)
          @@registered_commands[normalize_name(name)] = klass
        end

        def find(name)
          @@registered_commands[normalize_name(name)] || Base
        end

        # Parses the response for the request of the command and returns
        # response object.
        #
        # @param [Groonga::Command::Base] The command of the request.
        # @param [String] The raw (not parsed) response returned by groonga
        #   server.
        # @return [Base]
        def parse(command, raw_response)
          klass = find(command.command_name)
          klass.parse(command, raw_response)
        end

        private
        def normalize_name(name)
          case name
          when String
            name.to_sym
          else
            name
          end
        end
      end

      class Base
        class << self
          def parse(command, raw_response)
            case command.output_type
            when :json
              header, body = JSON.parse(raw_response)
            when :xml
              header, body = parse_xml(raw_response)
            else
              header = nil
              body = raw_response
            end
            if header.nil? or header[0].zero?
              response = new(command, header, body)
            else
              response = Error.new(command, header, body)
            end
            response.raw = raw_response
            response
          end

          private
          def parse_xml(response)
            # FIXME: Use more fast XML parser
            # Extract as a class
            document = REXML::Document.new(response)
            root_element = document.root
            if root_element.name == "RESULT"
              result_element = root_element
              header = parse_xml_header(result_element)
              body = parse_xml_body(result_element.elements[1])
            else
              header = nil
              body = parse_xml_body(root_element)
            end
            [header, body]
          end

          def parse_xml_header(result_element)
            attributes = result_element.attributes
            code    = Integer(attributes["CODE"])
            up      = Float(attributes["UP"])
            elapsed = Float(attributes["ELAPSED"])
            [code, up, elapsed]
          end

          def parse_xml_body(body_element)
            xml_to_ruby(body_element)
          end

          def xml_to_ruby(element)
            elements = element.elements
            if elements.empty?
              case element.name
              when "NULL"
                nil
              when "INT"
                Integer(element.text)
              else
                element.text
              end
            else
              elements.collect do |child|
                xml_to_ruby(child)
              end
            end
          end
        end

        # @return [Groonga::Command] The command for the request.
        attr_accessor :command
        # @return [::Array<Integer, Float, Float>] The header of response.
        #   It consists of `[return_code, start_time, elapsed_time_in_seconds]`
        #   for success case.
        #   It consists of
        #   `[return_code, start_time, elapsed_time_in_seconds, error_message, error_location]`
        #   for error case.
        # @see http://groonga.org/docs/reference/command/output_format.html#header
        #   Details for header format.
        attr_accessor :header
        # @return [::Hash] The body of response. Its content is depends on
        #   command.
        # @see http://groonga.org/docs/reference/command.html
        #   The list of built-in commands.
        attr_accessor :body
        # @return [String] The unparsed response. It may be JSON, XML or
        #   groonga command format.
        attr_accessor :raw

        def initialize(command, header, body)
          self.command = command
          self.header = header
          self.body = body
          self.raw = nil
        end

        # @return [Integer] The status code of the response.
        # @since 0.1.0
        def status_code
          (header || [0])[0]
        end

        # @return [Time] The time of the request is accepted.
        # @since 0.1.0
        def start_time
          Time.at((header || [0, 0])[1])
        end

        # @return [Time] The elapsed time of the request.
        # @since 0.1.0
        def elapsed_time
          (header || [0, 0, 0.0])[2]
        end

        # @return [String, nil] The error message of the response.
        # @since 0.2.4
        def error_message
          (header || [0, 0, 0.0, nil])[3]
        end

        # @return [Boolean] `true` if the request is processed successfully,
        #   `false` otherwise.
        # @since 0.1.0
        def success?
          status_code.zero?
        end
      end
    end
  end
end
