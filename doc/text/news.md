# NEWS

## 0.4.1 - 2016-02-07

### Improvements

  * `Groonga::Client::Request::Base`: Supported number as parameter
    value.

  * `Groonga::Client::Response::Load#errors`: Added for `load
    --output_errors yes --command_version 3`.

  * `Groonga::Client::Request::Select::DynamicColumnWindow#group_keys`:
    Added for `select --columns[LABEL].window.group_keys`. You can use
    this method by `request.columns(LABEL).window.group_keys(KEYS)`.

## 0.4.0 - 2016-01-12

### Improvements

  * `Groonga::Client::Request::Select#columns`: Supported
    `columns[label]`.

### Fixes

  * Removed Active Support method use.

  * `Groonga::Client::Request::Select#filter`: Fixed filter value
    escape error.

## 0.3.9 - 2016-12-22

### Improvements

  * `Groonga::Client::Request::Error`: Added more information.

## 0.3.8 - 2016-12-21

### Improvements

  * `Groonga::Client::Request::Select#filter`: Supported
    `filter(column_name, value)` usage. It's a shortcut of
    `filter("#{column_name} == %{value}", value: value)`.

## 0.3.7 - 2016-12-20

### Improvements

  * `Groonga::Client::Test::GroongaServerRunner`: Supported
    customizing Groonga server URL.

## 0.3.6 - 2016-12-20

### Improvements

  * Added `Groonga::Client::Test::GroongaServerRunner#using_running_server?`.

  * Merged groonga-client-cli. Now `groonga-client` command is available.

  * `Groonga::Client::Response::Schema#plugins`: Supported method access.

  * `Groonga::Client::Test::GroongaServerRunner`: Supported restoring
    DB for existing server.

## 0.3.5 - 2016-12-19

### Improvements

  * `Groonga::Client::Response::Schema::Column#value_type`: Made
    `value_type` elements method accessable.

## 0.3.4 - 2016-12-13

### Improvements

  * Added request interface from groonga-client-rails.

  * Added
    `Groonga::Client::Response::Schema::Index#full_text_searchable?`.

  * Added
    `Groonga::Client::Response::Schema::Column#have_full_text_search_index?`.

  * Added
    `Groonga::Client::Response::Schema::Table#have_full_text_search_index?`.

  * Added `Groonga::Client::Response::Select#slices`.

  * Added test helper from groonga-client-rails.

  * Added `Groonga::Client::Response#size` for Kaminari.

  * Added enumrable interface for `Groonga::Client::Response::Select`.

## 0.3.3 - 2016-12-07

### Improvements

  * `Groonga::Load#loaded_ids`: Renamed from
    `Groonga::Load#ids`. Because it's renamed in Groonga.

## 0.3.2 - 2016-12-06

### Improvements

  * `Groonga::Load#n_loaded_records`: Added. It's a convenience method
    to get the number of loaded records.

  * `Groonga::Load#ids`: Added. It's for `load --output_ids yes
    --command_version 3` that can be used with Groonga 6.1.2 or later.

## 0.3.1 - 2016-10-11

### Improvements

  * `Groonga::Client#select`: Supported labeled drilldowns.

  * `Groonga::Client::Response::Select#drilldowns`: Changed return
    type for the following cases:

      * Labeled drilldowns are used.

      * Command version 3 or later is used.

    It returns `{"label1" => drilldown1, "label2" => drilldown2}`
    instead of `[drilldown1, drilldown2]`. It's a backward
    incompatibility change for command version 3 or later case. But we
    did it because command version 3 is still experimental version.

## 0.3.0 - 2016-10-05

### Fixes

  * `Groonga::Client#select`: Accepted string and symbol as parameter
    key at once again.

## 0.2.9 - 2016-10-05

### Fixes

  * `Groonga::Client#select`: Accepted symbol as parameter key again.

## 0.2.8 - 2016-10-05

### Improvements

  * Added more documents.

### Fixes

  * `Groonga::Client#select`: Accepted string as parameter key again.

## 0.2.7 - 2016-08-19

### Improvements

  * HTTP: Added `:chunk` option to use `Transfer-Encoding: chunked`
    request.

## 0.2.6 - 2016-06-17

### Improvements

  * Supported command version 3.

  * Added {Groonga::Client::Response#return_code}.
    {Groonga::Client::Response#status_code} is deprecated. Use
    `#return_code` instead.

  * `select` response: Supported vector of `Time`.

## 0.2.5 - 2016-04-02

### Fixes

  * Fixed a bug that URL can't be specified by `String`.
    [GitHub#9][Reported by KITAITI Makoto]

### Thanks

  * KITAITI Makoto

## 0.2.4 - 2016-03-28

### Improvements

  * response: Added `Groonga::Client::Response::Base#error_message`.

## 0.2.3 - 2016-03-22

### Improvements

  * response: Supported `lock_clear` command.

  * response: Supported `schema` command partially.

## 0.2.2 - 2016-03-22

### Improvements

  * response: `schema`: Supported index.

  * response: `schema`: Supported normalizer.

  * response: `schema`: Supported token filter.

  * response: `schema`: Supported tokenizer.

### Fixes

  * Fixed a bug that `Groonga::Command` isn't accepted.

## 0.2.1 - 2016-03-21

### Improvements

  * HTTP: Supported path.

  * HTTP: Accepted `nil` as `:read_timeout` value.

## 0.2.0 - 2016-03-21

### Improvements

  * HTTP: Supported basic authentication.
    [GitHub#4][Patch by KITAITI Makoto]

  * response: Supported `table_remove`.
    [GitHub#7][Patch by Masafumi Yokoyama]

  * HTTP: Supported HTTPS by passing `:use_tls => true` option to
    {Groonga::Client.new}.
    [GitHub#8][Patch by KITAITI Makoto]

  * Supported URI as server information in {Groonga::Client.new}.

  * Required groonga-command 1.2.0 or later.

  * Accepted `Symbol` as registered command name.

  * Supported dynamic command execution. Now, you can use commands
    that aren't supported in groonga-client yet.

  * Added {Groonga::Client.default_options}.

  * Added {Groonga::Client.default_options=}.

### Thanks

  * KITAITI Makoto

  * Masafumi Yokoyama

## 0.1.9 - 2015-09-04

### Improvements

  * {Groonga::Client::ScriptSyntax#format_string}: Added a method that
    formats the given Ruby `String` as string
    [in Groonga's script syntax](http://groonga.org/docs/reference/grn_expr/script_syntax.html#string).

## 0.1.8 - 2015-08-08

### Improvements

  * `load`: Supported `Array` as `values` value.

## 0.1.7 - 2015-07-08

### Improvements

  * select: Avoided response value isn't accessible by response column
    name duplication. Data access key for duplicated column name has
    `2`, `3`, ... suffix such as `html_escape2` and `html_escape3`.
    [groonga-dev,03348][Reported by Hiroyuki Sato]

### Thanks

  * Hiroyuki Sato

## 0.1.6 - 2015-06-10

### Fixes

  * Re-added required file.

## 0.1.5 - 2015-06-10

### Fixes

  * Removed `require` for nonexistent file.

## 0.1.4 - 2015-06-10

### Changes

  * Moved `groonga-client` command to groonga-client-cli gem.
    It's an incompatible change.

## 0.1.3 - 2015-05-25

### Improvements

  * Stopped to use yajl-ruby.

## 0.1.2 - 2015-05-13

### Improvements

  * groonga-client: Supported split load.
  * groonga-client: Added `--read-timeout` option.

## 0.1.1 - 2015-04-20

### Improvements

  * groonga-client: Added a command that sends Groonga commands to a
    Groonga server.

## 0.1.0 - 2014-11-05

### Improvements

  * response: Added {Groonga::Client::Response::Error#message}.
  * response: Added {Groonga::Client::Response::Base#status_code}.
  * response: Added {Groonga::Client::Response::Base#start_time}.
  * response: Added {Groonga::Client::Response::Base#elapsed_time}.
  * response: Added {Groonga::Client::Response::Base#success?}.

## 0.0.9 - 2014-09-30

### Improvements

  * HTTP: Supported "load" by POST.
  * HTTP: Added synchronous backend.

## 0.0.8 - 2014-05-12

### Improvements

  * HTTP, Thread: Supported "bad request" response.
  * HTTP, Thread: Supported JSON body in "internal server error" response.

## 0.0.7 - 2014-03-28

### Improvements

  * Supported error response.

## 0.0.6 - 2014-03-25

### Fixes

  * HTTP, Cool.io: Fixed a bug that body is handled when body is
    partially read.

## 0.0.5 - 2014-03-25

### Improvements

  * Wrapped internal connection errors by
    `Groonga::Client::Connection::Error`.
  * Supported asynchronous request by calling with block.
  * Added Cool.io HTTP backend.

### Changes

  * Changed protocol implementation module/directory name to
    `protocol` from `connection`.

### Fixes

  * Fixed a bug that options passed to `Groonga::Client.new` is
    changed destructively.

## 0.0.4 - 2013-10-29

### Improvements

  * http: Supported timeout error.
  * status: Added {Groonga::Client::Response::Status#alloc_count} and
    {Groonga::Client::Response::Status#n_allocations}.

## 0.0.3 - 2013-09-18

### Improvements

  * Supported "table_create" command.
  * {Groonga::Client.open} returns block value.
  * Supported {Groonga::Client#close}.
  * select: Supported auto time value conversion.
  * select: Renamed to {Groonga::Client::Response::Select#n_hits}
    from #n_records. It is a backward incompatible change.
  * Added {Groonga::Client::Connection::Error} as an abstracted error.
  * Required groonga-command 1.0.4 or later.

## 0.0.2 - 2013-07-08

### Improvements

  * Supported "select" command.
  * Supported Enumerable type interface in
    Response::TableList and Response::ColumnList

## 0.0.1 - 2013-06-27

Initial release!!!
