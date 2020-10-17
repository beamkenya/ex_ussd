defmodule AfricasTalking do
  alias ExUssd.State.Registry

  @behaviour ExUssd.Ussd

  @impl true
  def goto(internal_routing: internal_routing, menu: menu, api_parameters: api_parameters) do

    %{menu: current_menu, display: menu_string} = EXUssd.Common.goto(internal_routing: internal_routing, menu: menu, api_parameters: api_parameters)

    %{should_close: should_close} = current_menu
    output = case should_close do
      false -> "CON " <> menu_string
      true ->
        Registry.stop(internal_routing.session_id)
        "END " <> menu_string
    end
    {:ok, output}
  end

  @impl true
  def end_session(session_id: _session_id) do
    {:error, "handled by goto fn"}
  end
end
