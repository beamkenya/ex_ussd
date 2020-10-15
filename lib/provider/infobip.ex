defmodule Infobip do
  @behaviour ExUssd.Ussd

  @impl true
  def goto(internal_routing: _internal_routing, menu: menu, api_parameters: api_parameters) do
    response = menu.callback.(api_parameters)
    {:ok, response.title}
  end
end
