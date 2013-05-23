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

require "rexml/document"

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
            when :xml
              header, body = parse_xml(response)
            else
              header = nil
              body = response
            end
            new(header, body)
          end

          private
          def parse_xml(response)
            # FIXME: Use more fast XML parser
            # Extract as a class
            document = REXML::Document.new(response)
            result_element = document.root
            header = parse_xml_header(result_element)
            body = parse_xml_body(result_element.elements[1])
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

        attr_accessor :header, :body

        def initialize(header, body)
          @header = header
          @body = body
        end
      end
    end
  end
end
