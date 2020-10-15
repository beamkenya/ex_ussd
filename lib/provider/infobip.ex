defmodule Infobip do
  alias ExUssd.State.Registry
  alias ExUssd.Utils
  @behaviour ExUssd.Ussd

  @impl true
  def goto(internal_routing: _internal_routing, menu: menu, api_parameters: api_parameters) do
    response = Utils.call_menu_callback(menu, api_parameters)
    {:ok, response.title}
  end

  @impl true
  def end_session(session_id: session_id) do
    Registry.stop(session_id)
  end
end
