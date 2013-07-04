module TestResultsHelper
  def open_client
    Groonga::Client.open(:protocol => :http)
  end
end

