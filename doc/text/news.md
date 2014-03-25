# NEWS

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
