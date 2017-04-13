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
        # @param command [Groonga::Command::Base] The command of the request.
        #
        # @param raw_response [String] The raw (not parsed) response
        #   returned by Groonga server.
        #
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
            return_code = nil
            case command.output_type
            when :json
              response = JSON.parse(raw_response)
              if response.is_a?(::Array)
                header, body = response
                return_code = header[0] if header
              else
                header = response["header"]
                body = response["body"]
                return_code = header["return_code"] if header
              end
            when :xml
              header, body = parse_xml(raw_response)
              return_code = header[0] if header
            else
              header = nil
              body = raw_response
            end
            if header.nil? or return_code == 0
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
        #   Groonga command format.
        attr_accessor :raw

        def initialize(command, header, body)
          self.command = command
          self.header = header
          self.body = body
          self.raw = nil
        end

        # @return [Integer] The return code of the response.
        # @since 0.2.6
        def return_code
          if header.nil?
            0
          elsif header_v1?
            header[0]
          else
            header["return_code"] || 0
          end
        end

        # @return [Integer] The status code of the response.
        # @since 0.1.0
        #
        # @deprecated since 0.2.6. Use {return_code} instead.
        def status_code
          return_code
        end

        # @return [Time] The time of the request is accepted.
        # @since 0.1.0
        def start_time
          if header.nil?
            Time.at(0)
          elsif header_v1?
            Time.at(header[1])
          else
            Time.at(header["start_time"])
          end
        end

        # @return [Float] The elapsed time of the request.
        # @since 0.1.0
        def elapsed_time
          if header.nil?
            0.0
          elsif header_v1?
            header[2]
          else
            header["elapsed_time"]
          end
        end

        # @return [String, nil] The error message of the response.
        # @since 0.2.4
        def error_message
          if header.nil?
            nil
          elsif header_v1?
            header[3]
          else
            (header["error"] || {})["message"]
          end
        end

        # @return [Boolean] `true` if the request is processed successfully,
        #   `false` otherwise.
        # @since 0.1.0
        def success?
          return_code.zero?
        end

        private
        def header_v1?
          header.is_a?(::Array)
        end
      end
    end
  end
end
