defmodule ExUssd.NavigationValidationTest do
  use ExUnit.Case, async: true
  alias ExUssd.State.Registry

  setup_all do
    defmodule PinValidateHandler do
      @behaviour ExUssd.Handler
      def handle_menu(menu, api_parameters) do
        case api_parameters.text == "5555" do
          true ->
            menu
            |> Map.put(:title, "success, thank you.")
            |> Map.put(:should_close, true)

          _ ->
            menu |> Map.put(:error, "Wrong pin number\n")
        end
      end
    end

    defmodule MyHomeHandler do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu
        |> Map.put(:title, "Enter your pin number")
        |> Map.put(:validation_menu, ExUssd.Menu.render(name: "", handler: PinValidateHandler))
      end
    end

    internal_routing = %{session_id: "session_01", service_code: "*544#"}
    Registry.start(internal_routing.session_id)
    initial_menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)

    %{
      session_id: internal_routing.session_id,
      api_parameters: %{text: ""},
      initial_menu: initial_menu
    }
  end

  test "navigate to the initial menu", params do
    %{initial_menu: initial_menu} = params

    menu = simulate("", initial_menu, params)

    assert menu.title == "Enter your pin number"
    assert menu.error == nil
  end

  test "enter wrong pin", params do
    %{initial_menu: initial_menu} = params

    _menu = simulate("", initial_menu, params)
    menu = simulate("9999", initial_menu, params)
    assert menu.title == "Enter your pin number"
    assert menu.error == "Wrong pin number\n"
  end

  test "enter correct pin", params do
    %{initial_menu: initial_menu} = params

    _menu = simulate("", initial_menu, params)
    menu = simulate("5555", initial_menu, params)
    assert menu.title == "success, thank you."
  end

  def simulate(text, initial_menu, %{
        session_id: session_id,
        api_parameters: api_parameters
      }) do
    routes = ExUssd.Routes.get_route(%{text: text, service_code: "*544#"})
    menu = ExUssd.Utils.call_menu_callback(initial_menu)
    ExUssd.Navigation.navigate(session_id, routes, menu, api_parameters)
  end
end
