defmodule Infobip do
  alias ExUssd.State.Registry

  @behaviour ExUssd.Ussd

  @impl true
  def goto(internal_routing: internal_routing, menu: menu, api_parameters: api_parameters) do

    %{menu: current_menu, display: menu_string} = EXUssd.Common.goto(internal_routing: internal_routing, menu: menu, api_parameters: api_parameters)

    {:ok,
      %{
        shouldClose: current_menu.should_close,
        ussdMenu:  menu_string,
        responseExitCode: 200,
        responseMessage: ""
      }
    }
  end

  @impl true
  def end_session(session_id: session_id) do
    Registry.stop(session_id)
  end
end
