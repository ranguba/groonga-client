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

require "time"

require_relative "helper"

require "groonga/client/command-line/groonga-client-index-recreate"

class TestCommandLineIndexRecreate < Test::Unit::TestCase
  include Groonga::Client::TestHelper
  include CommandLineTestHelper

  def setup
    @now = Time.parse("2017-10-25T17:22:00+0900")
    stub(Time).now {@now}
  end

  def index_recreate(*arguments)
    command_line = Groonga::Client::CommandLine::GroongaClientIndexRecreate.new
    capture_outputs do
      command_line.run(["--url", groonga_url, *arguments])
    end
  end

  def test_no_alias_column
    index_recreate
    assert_equal(<<-DUMP.chomp, dump)
config_set alias.column Aliases.real_name

table_create Aliases TABLE_HASH_KEY ShortText
column_create Aliases real_name COLUMN_SCALAR ShortText
    DUMP
  end

  def test_real_index
    restore(<<-COMMANDS)
table_create Memos TABLE_HASH_KEY ShortText
column_create Memos content COLUMN_SCALAR Text

table_create Terms TABLE_PAT_KEY ShortText \
  --normalizer NormalizerAuto \
  --default_tokenizer TokenBigram
column_create Terms memos_content \
  COLUMN_INDEX|WITH_POSITION \
  Memos content
    COMMANDS

    assert_equal([true, "", ""],
                 index_recreate("Terms.memos_content"))

    assert_equal(<<-DUMP.chomp, dump)
config_set alias.column Aliases.real_name

table_create Aliases TABLE_HASH_KEY ShortText
column_create Aliases real_name COLUMN_SCALAR ShortText

table_create Memos TABLE_HASH_KEY ShortText
column_create Memos content COLUMN_SCALAR Text

table_create Terms TABLE_PAT_KEY ShortText --default_tokenizer TokenBigram --normalizer NormalizerAuto

load --table Aliases
[
["_key","real_name"],
["Terms.memos_content","Terms.memos_content_20171025"]
]

column_create Terms memos_content_20171025 COLUMN_INDEX|WITH_POSITION Memos content
    DUMP
  end

  def test_old_index
    restore(<<-COMMANDS)
config_set alias.column CustomAliases.name

table_create CustomAliases TABLE_HASH_KEY ShortText
column_create CustomAliases name COLUMN_SCALAR ShortText

table_create Memos TABLE_HASH_KEY ShortText
column_create Memos content COLUMN_SCALAR Text

table_create Terms TABLE_PAT_KEY ShortText \
  --normalizer NormalizerAuto \
  --default_tokenizer TokenBigram
column_create Terms memos_content_20171024 \
  COLUMN_INDEX|WITH_POSITION \
  Memos content

load --table CustomAliases
[
["_key","name"],
["Terms.memos_content","Terms.memos_content_20171024"]
]
    COMMANDS

    assert_equal([true, "", ""],
                 index_recreate("Terms.memos_content"))

    assert_equal(<<-DUMP.chomp, dump)
config_set alias.column CustomAliases.name

table_create CustomAliases TABLE_HASH_KEY ShortText
column_create CustomAliases name COLUMN_SCALAR ShortText

table_create Memos TABLE_HASH_KEY ShortText
column_create Memos content COLUMN_SCALAR Text

table_create Terms TABLE_PAT_KEY ShortText --default_tokenizer TokenBigram --normalizer NormalizerAuto

load --table CustomAliases
[
["_key","name"],
["Terms.memos_content","Terms.memos_content_20171025"]
]

column_create Terms memos_content_20171024 COLUMN_INDEX|WITH_POSITION Memos content
column_create Terms memos_content_20171025 COLUMN_INDEX|WITH_POSITION Memos content
    DUMP
  end

  def test_old_indexes
    restore(<<-COMMANDS)
config_set alias.column CustomAliases.name

table_create CustomAliases TABLE_HASH_KEY ShortText
column_create CustomAliases name COLUMN_SCALAR ShortText

table_create Memos TABLE_HASH_KEY ShortText
column_create Memos content COLUMN_SCALAR Text

table_create Terms TABLE_PAT_KEY ShortText \
  --normalizer NormalizerAuto \
  --default_tokenizer TokenBigram
column_create Terms memos_content_20171022 \
  COLUMN_INDEX|WITH_POSITION \
  Memos content
column_create Terms memos_content_20171023 \
  COLUMN_INDEX|WITH_POSITION \
  Memos content
column_create Terms memos_content_20171024 \
  COLUMN_INDEX|WITH_POSITION \
  Memos content

load --table CustomAliases
[
["_key","name"],
["Terms.memos_content","Terms.memos_content_20171024"]
]
    COMMANDS

    assert_equal([true, "", ""],
                 index_recreate("Terms.memos_content"))

    assert_equal(<<-DUMP.chomp, dump)
config_set alias.column CustomAliases.name

table_create CustomAliases TABLE_HASH_KEY ShortText
column_create CustomAliases name COLUMN_SCALAR ShortText

table_create Memos TABLE_HASH_KEY ShortText
column_create Memos content COLUMN_SCALAR Text

table_create Terms TABLE_PAT_KEY ShortText --default_tokenizer TokenBigram --normalizer NormalizerAuto

load --table CustomAliases
[
["_key","name"],
["Terms.memos_content","Terms.memos_content_20171025"]
]

column_create Terms memos_content_20171024 COLUMN_INDEX|WITH_POSITION Memos content
column_create Terms memos_content_20171025 COLUMN_INDEX|WITH_POSITION Memos content
    DUMP
  end

  def test_already_latest
    restore(<<-COMMANDS)
config_set alias.column CustomAliases.name

table_create CustomAliases TABLE_HASH_KEY ShortText
column_create CustomAliases name COLUMN_SCALAR ShortText

table_create Memos TABLE_HASH_KEY ShortText
column_create Memos content COLUMN_SCALAR Text

table_create Terms TABLE_PAT_KEY ShortText \
  --normalizer NormalizerAuto \
  --default_tokenizer TokenBigram
column_create Terms memos_content_20171022 \
  COLUMN_INDEX|WITH_POSITION \
  Memos content
column_create Terms memos_content_20171023 \
  COLUMN_INDEX|WITH_POSITION \
  Memos content
column_create Terms memos_content_20171024 \
  COLUMN_INDEX|WITH_POSITION \
  Memos content
column_create Terms memos_content_20171025 \
  COLUMN_INDEX|WITH_POSITION \
  Memos content

load --table CustomAliases
[
["_key","name"],
["Terms.memos_content","Terms.memos_content_20171025"]
]
    COMMANDS

    assert_equal([true, "", ""],
                 index_recreate("Terms.memos_content"))

    assert_equal(<<-DUMP.chomp, dump)
config_set alias.column CustomAliases.name

table_create CustomAliases TABLE_HASH_KEY ShortText
column_create CustomAliases name COLUMN_SCALAR ShortText

table_create Memos TABLE_HASH_KEY ShortText
column_create Memos content COLUMN_SCALAR Text

table_create Terms TABLE_PAT_KEY ShortText --default_tokenizer TokenBigram --normalizer NormalizerAuto

load --table CustomAliases
[
["_key","name"],
["Terms.memos_content","Terms.memos_content_20171025"]
]

column_create Terms memos_content_20171022 COLUMN_INDEX|WITH_POSITION Memos content
column_create Terms memos_content_20171023 COLUMN_INDEX|WITH_POSITION Memos content
column_create Terms memos_content_20171024 COLUMN_INDEX|WITH_POSITION Memos content
column_create Terms memos_content_20171025 COLUMN_INDEX|WITH_POSITION Memos content
    DUMP
  end

  def test_latest_alias_but_not_exist
    restore(<<-COMMANDS)
config_set alias.column CustomAliases.name

table_create CustomAliases TABLE_HASH_KEY ShortText
column_create CustomAliases name COLUMN_SCALAR ShortText

table_create Memos TABLE_HASH_KEY ShortText
column_create Memos content COLUMN_SCALAR Text

table_create Terms TABLE_PAT_KEY ShortText \
  --normalizer NormalizerAuto \
  --default_tokenizer TokenBigram
column_create Terms memos_content_20171022 \
  COLUMN_INDEX|WITH_POSITION \
  Memos content
column_create Terms memos_content_20171023 \
  COLUMN_INDEX|WITH_POSITION \
  Memos content
column_create Terms memos_content_20171024 \
  COLUMN_INDEX|WITH_POSITION \
  Memos content

load --table CustomAliases
[
["_key","name"],
["Terms.memos_content","Terms.memos_content_20171025"]
]
    COMMANDS

    assert_equal([
                   false,
                   "",
                   "Alias doesn't specify real index column: " +
                   "<Terms.memos_content_20171025>\n",
                 ],
                 index_recreate("Terms.memos_content"))

    assert_equal(<<-DUMP.chomp, dump)
config_set alias.column CustomAliases.name

table_create CustomAliases TABLE_HASH_KEY ShortText
column_create CustomAliases name COLUMN_SCALAR ShortText

table_create Memos TABLE_HASH_KEY ShortText
column_create Memos content COLUMN_SCALAR Text

table_create Terms TABLE_PAT_KEY ShortText --default_tokenizer TokenBigram --normalizer NormalizerAuto

load --table CustomAliases
[
["_key","name"],
["Terms.memos_content","Terms.memos_content_20171025"]
]

column_create Terms memos_content_20171022 COLUMN_INDEX|WITH_POSITION Memos content
column_create Terms memos_content_20171023 COLUMN_INDEX|WITH_POSITION Memos content
column_create Terms memos_content_20171024 COLUMN_INDEX|WITH_POSITION Memos content
    DUMP
  end
end
