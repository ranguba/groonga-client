# README

## Name

groonga-client

## Description

Groonga-client is a client for Groonga (http://groonga.org/)
implemented with pure Ruby. You can use it without Groonga.

Groonga-client gem supports HTTP or
[GQTP (Groonga Query Transfer Protocol)](http://groonga.org/docs/spec/gqtp.html)
as the protocol using a client.

## Install

    % gem install groonga-client

## Usage

Grooga-client handles protocol transparently, so there is only one
difference between HTTP and GQTP examples. It's `:protocol` parameter
value of `Groonga::Client.open`. It's `:http` for HTTP and `:gqtp` for
GQTP.

### HTTP

Here is a sample to get list of tables via HTTP protocol.

    require "groonga/client"

    host = "127.0.0.1"
    protocol = :http
    Groonga::Client.open(:host => host, :protocol => protocol) do |client|
      tables = client.table_list
      tables.each do |table|
        table.name
      end
    end

### GQTP

Here is a sample to get list of tables via GQTP protocol.

    require "groonga/client"

    host = "127.0.0.1"
    protocol = :gqtp
    Groonga::Client.open(:host => host, :protocol => protocol) do |client|
      tables = client.table_list
      tables.each do |table|
        table.name
      end
    end

### Typical example

Here is a typical example to learn usage of groonga-client. In this
example, it creates `User` table and `login_name` column. Then it
loads sample data and selects a person which contains `bob` as a key.

    require "groonga/client"

    host = "127.0.0.1"
    protocol = :http
    Groonga::Client.open(:host => host, :protocol => protocol) do |client|
      client.table_create(:name => "User",
                          :flags => "TABLE_PAT_KEY",
                          :key_type => "ShortText")
      client.column_create(:table => "User",
                           :name => "login_name",
                           :flags => "COLUMN_SCALAR",
                           :type => "ShortText")
      values = [
        {
          "_key" => "bob",
          "login_name" => "Bob"
        },
        {
          "_key" => "tim",
          "login_name" => "Tim"
        },
        {
          "_key" => "jessie",
          "login_name" => "Jessie"
        },
      ]
      client.load(:table => "User",
                  :values => values.to_json)
      response = client.select(:table => "User", :query => "_key:bob")
      if response.success?
        puts response.n_hits
        response.records.each do |record|
          puts record["login_name"]
        end
      else
        puts response.error_message
      end
    end

## Dependencies

* Ruby

## Mailing list

* English: [groonga-talk@lists.sourceforge.net](https://lists.sourceforge.net/lists/listinfo/groonga-talk)
* Japanese: [groonga-dev@lists.sourceforge.jp](http://lists.sourceforge.jp/mailman/listinfo/groonga-dev)

## Authors

* Haruka Yoshihara \<yoshihara@clear-code.com\>
* Kouhei Sutou \<kou@clear-code.com\>

## License

LGPLv2.1 or later. See doc/text/lgpl-2.1.txt for details.

(Kouhei Sutou has a right to change the license including contributed
patches.)
