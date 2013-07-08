class TestCommand < Test::Unit::TestCase
  def setup
    @client = Groonga::Client.open(:protocol => :http)
  end

  def test_column_create
    mock(@client).execute_command("column_create", :table => :Test, :name => :Body, :type => :ShortText) do
      Object.new
    end
    @client.column_create(:table => :Test, :name => :Body, :type => :ShortText)
  end

  def test_column_list
    mock(@client).execute_command("column_list", :table => :Test) do
      Object.new
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
    mock(@client).execute_command("load", :table => :Test, :values => values.to_json) do
      Object.new
    end
    @client.load(:table => :Test, :values => values.to_json)
  end

  def test_select
    mock(@client).execute_command("select", :table => :Test) do
      Object.new
    end
    @client.select(:table => :Test)
  end

  def test_table_create
    mock(@client).execute_command("table_create", :name => :Test) do
      Object.new
    end
    @client.table_create(:name => :Test)
  end

  def test_table_list
    mock(@client).execute_command("table_list", {}) do
      Object.new
    end
    @client.table_list
  end
end
