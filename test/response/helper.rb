module TestResponseHelper
  def make_command(command_name, parameters = {})
    command_class = Groonga::Command.find(command_name)
    command = command_class.new(command_name, parameters)
    Groonga::Client::Command.new(command)
  end
end
