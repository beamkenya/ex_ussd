defmodule App.Ussd do
  def start_session do
    ExUssd.new(name: "Home", handler: MyHomeHandler)
  end
end
