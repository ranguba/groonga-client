class TestCommand < Test::Unit::TestCase
  def open_client
    Groonga::Client.open(:protocol => :http)
  end

  def test_select
    client = open_client
    mock(client).execute_command("select", :table => :Test) do
      Object.new
    end
    client.select(:table => :Test)
  end

  def test_table_list
    client = open_client
    mock(client).execute_command("table_list", {}) do
      Object.new
    end
    client.table_list
  end
end
