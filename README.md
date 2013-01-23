# README

## Name

groonga-client

## Description

Groonga-client is a client for groonga (http://groonga.org/)
implemented with pure ruby.

Groonga-client gem supports HTTP or
[GQTP (Groonga Query Transfer Protocol)](http://groonga.org/docs/spec/gqtp.html)
as the protocol using a client. You can use it without groonga
package.

## Install

    % gem install groonga-client

## Usage

TODO: use commands with parameters for examples
(e.g. table_create, load, select)

### GQTP

  Groonga::Client.open(:host => host, :port => port, :protocol => :gqtp) do |client|
  tables = client.table_list
  tables.each do |table|
    table.name
  end

### HTTP

  Groonga::Client.open(:host => host, :port => port, :protocol => :http) do |client|
  tables = client.table_list
  tables.each do |table|
    table.name
  end

## Dependencies

* Ruby 1.9.3

## Mailing list

* English: [groonga-talk@lists.sourceforge.net](https://lists.sourceforge.net/lists/listinfo/groonga-talk)
* Japanese: [groonga-dev@lists.sourceforge.jp](http://lists.sourceforge.jp/mailman/listinfo/groonga-dev)

## Thanks

* ...

## Authors

* Haruka Yoshihara \<yoshihara@clear-code.com\>

## License

LGPLv2.1 or later. See doc/text/lgpl-2.1.txt for details.

(Kouhei Sutou has a right to change the license including contributed
patches.)
