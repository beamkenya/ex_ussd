defmodule ExUssd.NavigationTest do
  use ExUnit.Case, async: true
  alias ExUssd.Utils
  alias ExUssd.Routes
  alias ExUssd.Navigation
  alias ExUssd.State.Registry
  alias ExUssd.Menu
  alias ExUssd.Display
  setup do
    internal_routing = %{text: "1", session_id: "session_01", service_code: "*544#"}
    Registry.start(internal_routing.session_id)
  end

  test "navigate to (level 1)" do
    internal_routing = %{text: "*544#", session_id: "session_01", service_code: "*544#"}
    api_parameters = %{
      sessionId: "session_01",
      phoneNumber: "254722000000",
      networkCode: "Safaricom",
      serviceCode: "*544#",
      text: "1"
    }

    menu =
      Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
          |> Map.put(:title, "Home Page: Welcome")
        end
      )

    response = Utils.call_menu_callback(menu, api_parameters)

    route = Routes.get_route(%{text: internal_routing.text, service_code: internal_routing.service_code})

    current_menu = Navigation.navigate(internal_routing.session_id, route, response, api_parameters)

    current_routes = Registry.get("session_01")

    menu_string = Display.generate(menu: current_menu, routes: current_routes)

    assert menu_string == "Home Page: Welcome"
  end

  test "navigate to (level 2)" do
    internal_routing = %{text: "*544*1#", session_id: "session_01", service_code: "*544#"}
    api_parameters = %{
      sessionId: "session_01",
      phoneNumber: "254722000000",
      networkCode: "Safaricom",
      serviceCode: "*544#",
      text: "1"
    }

    menu =
      Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
            |> Map.put(:title, "Welcome")
            |> Map.put(:menu_list,
            [
              Menu.render(
              name: "child 1",
              handler: fn menu, _api_parameters, _should_handle ->
                menu
                |> Map.put(:title, "Welcome to child 1 page")
              end),
              Menu.render(
              name: "child 2",
              handler: fn menu, _api_parameters, _should_handle ->
                menu
                |> Map.put(:title, "Welcome to child 2 page")
              end),
            ])
        end
      )

    response = Utils.call_menu_callback(menu, api_parameters)

    route = Routes.get_route(%{text: internal_routing.text, service_code: internal_routing.service_code})

    current_menu = Navigation.navigate(internal_routing.session_id, route, response, api_parameters)

    current_routes = Registry.get("session_01")

    menu_string = Display.generate(menu: current_menu, routes: current_routes)

    assert menu_string == "Welcome to child 1 page\n0:BACK"
  end

  test "navigate to (level 2) simulate 1" do
    simulate_route = [%{depth: 1, value: "555"}]
    internal_routing = %{text: "1", session_id: "session_01", service_code: "*544#"}

    api_parameters = %{
      sessionId: "session_01",
      phoneNumber: "254722000000",
      networkCode: "Safaricom",
      serviceCode: "*544#",
      text: "1"
    }

    menu =
      Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
            |> Map.put(:title, "Welcome")
            |> Map.put(:menu_list,
            [
              Menu.render(
              name: "child 1",
              handler: fn menu, _api_parameters, _should_handle ->
                menu
                |> Map.put(:title, "Welcome to child 1 page")
              end),
              Menu.render(
              name: "child 2",
              handler: fn menu, _api_parameters, _should_handle ->
                menu
                |> Map.put(:title, "Welcome to child 2 page")
              end),
            ])
        end
      )

    response = Utils.call_menu_callback(menu, api_parameters)

    Navigation.navigate("session_01", simulate_route, response, api_parameters)

    route = Routes.get_route(%{text: internal_routing.text, service_code: internal_routing.service_code})

    current_menu = Navigation.navigate(internal_routing.session_id, route, response, api_parameters)

    current_routes = Registry.get("session_01")

    menu_string = Display.generate(menu: current_menu, routes: current_routes)

    assert menu_string == "Welcome to child 1 page\n0:BACK"
  end

  test "navigate to (level 1) simulate 0" do
    simulate_route = [%{depth: 1, value: "1"}, %{depth: 1, value: "555"}]
    internal_routing = %{text: "0", session_id: "session_01", service_code: "*544#"}

    api_parameters = %{
      sessionId: "session_01",
      phoneNumber: "254722000000",
      networkCode: "Safaricom",
      serviceCode: "*544#",
      text: "1"
    }

    menu =
      Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
            |> Map.put(:title, "Welcome")
            |> Map.put(:menu_list,
            [
              Menu.render(
              name: "child 1",
              handler: fn menu, _api_parameters, _should_handle ->
                menu
                |> Map.put(:title, "Welcome to child 1 page")
              end),
              Menu.render(
              name: "child 2",
              handler: fn menu, _api_parameters, _should_handle ->
                menu
                |> Map.put(:title, "Welcome to child 2 page")
              end),
            ])
        end
      )

    response = Utils.call_menu_callback(menu, api_parameters)

    Navigation.navigate("session_01", simulate_route, response, api_parameters)

    route = Routes.get_route(%{text: internal_routing.text, service_code: internal_routing.service_code})

    current_menu = Navigation.navigate(internal_routing.session_id, route, response, api_parameters)

    current_routes = Registry.get("session_01")

    menu_string = Display.generate(menu: current_menu, routes: current_routes)

    assert menu_string == "Welcome\n1:child 1\n2:child 2"
  end

  test "(level 1) simulate 98" do
    simulate_route = [%{depth: 1, value: "555"}]
    Registry.add("session_01", simulate_route)
    internal_routing = %{text: "98", session_id: "session_01", service_code: "*544#"}

    api_parameters = %{
      sessionId: "session_01",
      phoneNumber: "254722000000",
      networkCode: "Safaricom",
      serviceCode: "*544#",
      text: "1"
    }

    menu =
      Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
            |> Map.put(:title, "Welcome")
            |> Map.put(:menu_list,
            [
              Menu.render(
              name: "child 1",
              handler: fn menu, _api_parameters, _should_handle ->
                menu
                |> Map.put(:title, "Welcome to child 1 page")
              end),
              Menu.render(
              name: "child 2",
              handler: fn menu, _api_parameters, _should_handle ->
                menu
                |> Map.put(:title, "Welcome to child 2 page")
              end),
              Menu.render(
              name: "child 3",
              handler: fn menu, _api_parameters, _should_handle ->
                menu
                |> Map.put(:title, "Welcome to child 3 page")
              end),
              Menu.render(
              name: "child 4",
              handler: fn menu, _api_parameters, _should_handle ->
                menu
                |> Map.put(:title, "Welcome to child 4 page")
              end),
            ])
            |> Map.put(:split, 2)
        end
      )

    response = Utils.call_menu_callback(menu, api_parameters)

    Navigation.navigate("session_01", simulate_route, response, api_parameters)

    route = Routes.get_route(%{text: internal_routing.text, service_code: internal_routing.service_code})

    current_menu = Navigation.navigate(internal_routing.session_id, route, response, api_parameters)

    current_routes = Registry.get("session_01")

    menu_string = Display.generate(menu: current_menu, routes: current_routes)

    assert menu_string == "Welcome\n3:child 3\n4:child 4\n0:BACK"
  end

  test "(level 1) depth 2 simulate 0" do
    simulate_route = [%{depth: 2, value: "555"}]
    Registry.add("session_01", simulate_route)
    internal_routing = %{text: "0", session_id: "session_01", service_code: "*544#"}

    api_parameters = %{
      sessionId: "session_01",
      phoneNumber: "254722000000",
      networkCode: "Safaricom",
      serviceCode: "*544#",
      text: "1"
    }

    menu =
      Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
            |> Map.put(:title, "Welcome")
            |> Map.put(:menu_list,
            [
              Menu.render(
              name: "child 1",
              handler: fn menu, _api_parameters, _should_handle ->
                menu
                |> Map.put(:title, "Welcome to child 1 page")
              end),
              Menu.render(
              name: "child 2",
              handler: fn menu, _api_parameters, _should_handle ->
                menu
                |> Map.put(:title, "Welcome to child 2 page")
              end),
              Menu.render(
              name: "child 3",
              handler: fn menu, _api_parameters, _should_handle ->
                menu
                |> Map.put(:title, "Welcome to child 3 page")
              end),
              Menu.render(
              name: "child 4",
              handler: fn menu, _api_parameters, _should_handle ->
                menu
                |> Map.put(:title, "Welcome to child 4 page")
              end),
            ])
            |> Map.put(:split, 2)
        end
      )

    response = Utils.call_menu_callback(menu, api_parameters)

    Navigation.navigate("session_01", simulate_route, response, api_parameters)

    route = Routes.get_route(%{text: internal_routing.text, service_code: internal_routing.service_code})

    current_menu = Navigation.navigate(internal_routing.session_id, route, response, api_parameters)

    current_routes = Registry.get("session_01")

    menu_string = Display.generate(menu: current_menu, routes: current_routes)

    assert menu_string == "Welcome\n1:child 1\n2:child 2\n98:MORE"
  end

  test "validate client input" do
    simulate_route = [%{depth: 1, value: "555"}]
    Registry.add("session_01", simulate_route)
    internal_routing = %{text: "5342", session_id: "session_01", service_code: "*544#"}

    api_parameters = %{
      sessionId: "session_01",
      phoneNumber: "254722000000",
      networkCode: "Safaricom",
      serviceCode: "*544#",
      text: "1"
    }

    menu =
      Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
            |> Map.put(:title, "Enter Pin Number")
            |> Map.put(:menu_list,
            [
              Menu.render(
              name: "",
              handler: fn menu, api_parameters, should_handle ->
                case should_handle do
                  true ->
                    case api_parameters.text == "5342" do
                      true ->
                        menu
                        |> Map.put(:title, "Welcome Back")
                        |> Map.put(:success, true)
                      _->
                        menu |> Map.put(:error, "Invalid Pin Number")
                    end
                  false -> menu
                end
              end)
            ])
            |> Map.put(:handle, true)
            |> Map.put(:show_options, false)
        end
      )

    response = Utils.call_menu_callback(menu, api_parameters)

    Navigation.navigate("session_01", simulate_route, response, api_parameters)

    route = Routes.get_route(%{text: internal_routing.text, service_code: internal_routing.service_code})

    current_menu = Navigation.navigate(internal_routing.session_id, route, response, api_parameters)

    current_routes = Registry.get("session_01")

    menu_string = Display.generate(menu: current_menu, routes: current_routes)

    assert menu_string == "Welcome Back\n0:BACK"
  end
end
