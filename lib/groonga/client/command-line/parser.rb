# Copyright (C) 2015-2017  Kouhei Sutou <kou@clear-code.com>
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

require "optparse"

require "groonga/client"

module Groonga
  class Client
    module CommandLine
      class Parser
        def initialize(options={})
          @url      = nil
          @protocol = :http
          @host     = "localhost"
          @port     = nil

          @read_timeout = options[:read_timeout] || Client::Default::READ_TIMEOUT
        end

        def parse(arguments)
          parser = OptionParser.new
          parser.version = VERSION

          parser.separator("")

          parser.separator("Connection:")

          parser.on("--url=URL",
                    "URL to connect to Groonga server.",
                    "If this option is specified,",
                    "--protocol, --host and --port are ignored.") do |url|
            @url = url
          end

          available_protocols = [:http, :gqtp]
          parser.on("--protocol=PROTOCOL", [:http, :gqtp],
                    "Protocol to connect to Groonga server.",
                    "[#{available_protocols.join(", ")}]",
                    "(#{@protocol})") do |protocol|
            @protocol = protocol
          end

          parser.on("--host=HOST",
                    "Groonga server to be connected.",
                    "(#{@host})") do |host|
            @host = host
          end

          parser.on("--port=PORT", Integer,
                    "Port number of Groonga server to be connected.",
                    "(auto)") do |port|
            @port = port
          end

          parser.on("--read-timeout=TIMEOUT", Integer,
                    "Timeout on reading response from Groonga server.",
                    "You can disable timeout by specifying -1.",
                    "(#{@read_timeout})") do |timeout|
            @read_timeout = timeout
          end

          yield(parser)

          rest = parser.parse(arguments)

          @port ||= default_port(@protocol)

          rest
        end

        def open_client(options={})
          default_options = {
            :url      => @url,
            :protocol => @protocol,
            :host     => @host,
            :port     => @port,
            :read_timeout => @read_timeout,
            :backend  => :synchronous,
          }
          Client.open(default_options.merge(options)) do |client|
            yield(client)
          end
        end

        private
        def default_port(protocol)
          case protocol
          when :http
            10041
          when :gqtp
            10043
          end
        end
      end
    end
  end
end
