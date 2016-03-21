require "groonga/client/response/base"

module Groonga
  class Client
    module Response
      class TableCreate < Base
        Response.register("table_create", self)
      end
    end
  end
end

