module TestResponseHelper
  def parse_raw_response(command_name, raw_response)
    make_command(command_name).send(:parse_raw_response, raw_response)
  end

  def make_command(command_name, parameters={})
    command_class = Groonga::Command.find(command_name)
    command = command_class.new(command_name, parameters)
    Groonga::Client::Command.new(command)
  end
end
