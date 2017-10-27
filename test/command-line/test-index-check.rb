# Copyright (C) 2017  Kouhei Sutou <kou@clear-code.com>
# Copyright (C) 2017  Kentaro Hayashi <hayashi@clear-code.com>
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

require_relative "helper"

require "groonga/client/command-line/groonga-client-index-check"

class TestCommandLineIndexCheck < Test::Unit::TestCase
  include Groonga::Client::TestHelper
  include CommandLineTestHelper

  def run_client_index_check(*arguments)
    command_line = Groonga::Client::CommandLine::GroongaClientIndexCheck.new
    capture_outputs do
      command_line.run(["--url", groonga_url, *arguments])
    end
  end

  def test_source
    restore(<<-COMMANDS)
table_create Memos TABLE_HASH_KEY ShortText
column_create Memos content COLUMN_SCALAR Text

table_create Terms TABLE_PAT_KEY ShortText \
  --normalizer NormalizerAuto \
  --default_tokenizer TokenBigram
column_create Terms memos_content \
  COLUMN_INDEX|WITH_POSITION \
  Memos
    COMMANDS

    expected = <<CLIENT_OUTPUT
index column:<Terms.memos_content> is missing source.
CLIENT_OUTPUT

    assert_equal([false, expected, ""],
                 run_client_index_check("--method=source",
                                        "Terms.memos_content"))
  end

  def test_content
    restore(<<-COMMANDS)
table_create Memos TABLE_HASH_KEY ShortText
column_create Memos content COLUMN_SCALAR Text

table_create Terms TABLE_PAT_KEY ShortText \
  --normalizer NormalizerAuto \
  --default_tokenizer TokenBigram
column_create Terms memos_content \
  COLUMN_INDEX|WITH_POSITION \
  Memos content

load --table Memos
[
["_key", "content"],
["groonga", "Groonga is fast"]
]
    COMMANDS

    expected = <<CLIENT_OUTPUT
check 3 tokens against <Terms.memos_content>.
CLIENT_OUTPUT

    assert_equal([true, expected, ""],
                 run_client_index_check("--method=content",
                                        "Terms.memos_content"))
  end
end
