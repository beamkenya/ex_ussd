defmodule EXUssd.Common do
  alias ExUssd.Utils
  # alias ExUssd.Routes
  alias ExUssd.Navigation
  alias ExUssd.Display
  alias ExUssd.State.Registry

  def goto(
        internal_routing: internal_routing,
        menu: menu,
        api_parameters: api_parameters,
        route: route
      ) do
    Registry.start(internal_routing.session_id)

    api_parameters = for {key, val} <- api_parameters, into: %{}, do: {String.to_atom(key), val}

    response =
      case ExUssd.State.Registry.get_home_menu(internal_routing.session_id) do
        nil ->
          home_menu = Utils.call_menu_callback(menu, api_parameters)
          current_menu = %{home_menu | parent: fn -> %{home_menu | error: nil} end}
          ExUssd.State.Registry.set_home_menu(internal_routing.session_id, current_menu)
          home_menu

        _ ->
          ExUssd.State.Registry.get_current_menu(internal_routing.session_id)
      end

    ExUssd.State.Registry.set_current_menu(internal_routing.session_id, response)
    ExUssd.State.Registry.set_menu(internal_routing.session_id, response)

    current_menu =
      Navigation.navigate(internal_routing.session_id, route, response, api_parameters)

    current_routes = Registry.get(internal_routing.session_id)

    {:ok, menu_string} =
      Display.generate(
        menu: current_menu,
        routes: current_routes,
        api_parameters: api_parameters
      )

    %{menu: current_menu, display: menu_string}
  end
end
