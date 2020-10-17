defmodule EXUssd.Common do
  alias ExUssd.Utils
  alias ExUssd.Routes
  alias ExUssd.Navigation
  alias ExUssd.Display
  alias ExUssd.State.Registry

  def goto(internal_routing: internal_routing, menu: menu, api_parameters: api_parameters) do

    Registry.start(internal_routing.session_id)

    response = Utils.call_menu_callback(menu, api_parameters)

    route = Routes.get_route(%{text: internal_routing.text, service_code: internal_routing.service_code})

    current_menu = Navigation.navigate(internal_routing.session_id, route, response, api_parameters)

    current_routes = Registry.get(internal_routing.session_id)

    menu_string = Display.generate(menu: current_menu, routes: current_routes)

    %{menu: current_menu, display: menu_string}
  end
end