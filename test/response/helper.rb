# Copyright (C) 2013  Kouhei Sutou <kou@clear-code.com>
# Copyright (C) 2013  Kosuke Asami
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

module TestResponseHelper
  def parse_raw_response_raw(command_name, pair_arguments, raw_response)
    command_class = Groonga::Command.find(command_name)
    command = command_class.new(command_name, pair_arguments)
    Groonga::Client::Response.parse(command, raw_response)
  end

  def parse_raw_response(command_name, raw_response)
    parse_raw_response_raw(command_name, {}, raw_response)
  end

  def parse_raw_xml_response(command_name, raw_response)
    parse_raw_response_raw(command_name, {"output_type" => "xml"},
                           raw_response)
  end
end
