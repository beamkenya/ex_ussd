defmodule ExUssd.NavigationValidationTest do
  use ExUnit.Case, async: true
  alias ExUssd.State.Registry

  setup do
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

    %{menu: menu} = ExUssd.Utils.navigate("", initial_menu, "session_006")

    assert menu.title == "Enter your pin number"
    assert menu.error == nil
  end

  test "enter wrong pin", params do
    %{initial_menu: initial_menu} = params

    %{menu: _menu} = ExUssd.Utils.navigate("", initial_menu, "session_007")
    %{menu: menu} = ExUssd.Utils.navigate("9999", initial_menu, "session_007")
    assert menu.title == "Enter your pin number"
    assert menu.error == "Wrong pin number\n"
  end

  test "enter correct pin", params do
    %{initial_menu: initial_menu} = params

    %{menu: _menu} = ExUssd.Utils.navigate("", initial_menu, "session_008")
    %{menu: menu} = ExUssd.Utils.navigate("5555", initial_menu, "session_008")
    assert menu.title == "success, thank you."
  end
end
