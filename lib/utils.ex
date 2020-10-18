defmodule ExUssd.Utils do
  def call_menu_callback(
        %ExUssd.Menu{} = menu,
        %{} = api_parameters \\ %{},
        should_handle \\ false
      ) do
    menu.callback.(api_parameters, should_handle)
  end

  def simulate(text: text, session_id: session_id, menu: menu) do
    internal_routing = %{text: text, session_id: session_id, service_code: "*544#"}

    api_parameters = %{
      sessionId: internal_routing.session_id,
      phoneNumber: "254722000000",
      networkCode: "Safaricom",
      serviceCode: internal_routing.service_code,
      text: internal_routing.text
    }

    route =
      ExUssd.Routes.get_route(%{
        text: internal_routing.text,
        service_code: internal_routing.service_code
      })

    %{menu: current_menu, display: menu_string} =
      EXUssd.Common.goto(
        internal_routing: internal_routing,
        menu: menu,
        api_parameters: api_parameters,
        route: route
      )

    %{should_close: should_close} = current_menu

    case should_close do
      false ->
        {:ok, menu_string}

      true ->
        ExUssd.State.Registry.stop(internal_routing.session_id)
        {:ok, menu_string}
    end
  end
end
