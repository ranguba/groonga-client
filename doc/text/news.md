# NEWS

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
