# Copyright (C) 2017  Kouhei Sutou <kou@clear-code.com>
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

require "groonga/command/parser"

require "groonga/client"
require "groonga/client/test-helper"
require "groonga/client/command-line/groonga-client-index-recreate"

class TestCommandLineIndexRecreate < Test::Unit::TestCase
  include Groonga::Client::TestHelper

  def groonga_url
    @groonga_server_runner.url.to_s
  end

  def dump
    Groonga::Client.open(:url => groonga_url) do |client|
      client.dump.body
    end
  end

  def index_recreate(*arguments)
    command_line = Groonga::Client::CommandLine::GroongaClientIndexRecreate.new
    command_line.run(["--url", groonga_url, *arguments])
  end

  def test_no_alias
    index_recreate
    assert_equal(<<-DUMP.chomp, dump)
config_set alias.column Aliases.real_name

table_create Aliases TABLE_HASH_KEY ShortText
column_create Aliases real_name COLUMN_SCALAR ShortText
    DUMP
  end
end
