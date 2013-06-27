require "groonga/client"

class TestCommandSelect < Test::Unit::TestCase
  def setup
    @db_path ||= File.join(__dir__, 'db' ,'test-select.db')
    setup_database
    @server_pid ||= launch_groonga_server
  end

  def teardown
    Process.kill('KILL', @server_pid)
    FileUtils.rm_rf(File.dirname(@db_path))
  end

  def test_select
    client = Groonga::Client.open(:protocol => :http)
    expected = [[[1], [["_id", "UInt32"]], [1]]]
    assert_equal(expected, client.select(:table => :Tests).body)
  end

  def setup_database
    FileUtils.mkdir_p(File.dirname(@db_path))

    piped_stdin, stdin = IO.pipe
    pid = spawn(open_db_command, :in => piped_stdin, :out => '/dev/null')
    stdin.write(groonga_setup_db_command)
    stdin.write(groonga_load_record_command)
    stdin.flush
    stdin.close

    Process.waitpid pid
  end

  def launch_groonga_server
    pid = spawn(launch_groonga_server_command, :out => '/dev/null')
    return pid
  end

  def launch_groonga_server_command
    return 'groonga --protocol http -s ' + @db_path
  end

  def open_db_command
    command = 'groonga'
    if !File.exists?(@db_path)
      command << ' -n'
    end
    command << ' ' + @db_path
    return command
  end

  def groonga_load_record_command
    <<CMD
load --table Tests --values [{}]
CMD
  end

  def groonga_setup_db_command
    <<CMD
table_create Tests TABLE_NO_KEY
CMD
  end

  def fixture_path(basename)
    File.join(__dir__, 'fixtures', basename)
  end
end

