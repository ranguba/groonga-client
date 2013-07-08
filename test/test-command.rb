class TestCommand < Test::Unit::TestCase
  def setup
    @client = Groonga::Client.open(:protocol => :http)
  end

  def test_column_create
    response = Object.new
    mock(@client).execute_command("column_create", :table => :Test, :name => :Body, :type => :ShortText) do
      response
    end
    @client.column_create(:table => :Test, :name => :Body, :type => :ShortText)
  end

  def test_column_list
    response = Object.new
    mock(@client).execute_command("column_list", :table => :Test) do
      response
    end
    @client.column_list(:table => :Test)
  end

  def test_load
    values = [
      {
        :_key => "Groonga",
        :body => "It's very fast!!"
      }
    ]
    response = Object.new
    mock(@client).execute_command("load", :table => :Test, :values => values.to_json) do
      response
    end
    @client.load(:table => :Test, :values => values.to_json)
  end

  def test_select
    response = Object.new
    mock(@client).execute_command("select", :table => :Test) do
      response
    end
    @client.select(:table => :Test)
  end

  def test_table_create
    response = Object.new
    mock(@client).execute_command("table_create", :name => :Test) do
      response
    end
    @client.table_create(:name => :Test)
  end

  def test_table_list
    response = Object.new
    mock(@client).execute_command("table_list", {}) do
      response
    end
    @client.table_list
  end
end
