defmodule Infobip do
  alias ExUssd.State.Registry
  alias ExUssd.Routes

  @behaviour ExUssd.Ussd

  @impl true
  def goto(internal_routing: internal_routing, menu: menu, api_parameters: api_parameters) do
    route =
      Routes.get_route(%{text: internal_routing.text, service_code: internal_routing.service_code})

    %{menu: current_menu, display: menu_string} =
      EXUssd.Common.goto(
        internal_routing: internal_routing,
        menu: menu,
        api_parameters: api_parameters,
        route: route
      )

    {:ok,
     %{
       shouldClose: current_menu.should_close,
       ussdMenu: menu_string,
       responseExitCode: 200,
       responseMessage: ""
     }}
  end

  @impl true
  def end_session(session_id: session_id) do
    Registry.stop(session_id)
  end
end
