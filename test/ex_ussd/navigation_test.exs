defmodule ExUssd.NavigationTest do
  use ExUnit.Case, async: true
  alias ExUssd.State.Registry

  setup do
    defmodule ProductAHandler do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu |> Map.put(:title, "selected product a")
      end
    end

    defmodule ProductBHandler do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu |> Map.put(:title, "selected product b")
      end
    end

    defmodule ProductCHandler do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu |> Map.put(:title, "selected product c")
      end
    end

    defmodule MyHomeHandler do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu
        |> Map.put(:title, "Welcome")
        |> Map.put(:split, 2)
        |> Map.put(
          :menu_list,
          [
            ExUssd.Menu.render(name: "Product A", handler: ProductAHandler),
            ExUssd.Menu.render(name: "Product B", handler: ProductBHandler),
            ExUssd.Menu.render(name: "Product C", handler: ProductCHandler)
          ]
        )
      end
    end

    internal_routing = %{session_id: "session_01", service_code: "*544#"}
    Registry.start(internal_routing.session_id)
    initial_menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)

    %{
      session_id: internal_routing.session_id,
      initial_menu: initial_menu
    }
  end

  test "navigate to the initial menu", params do
    %{initial_menu: initial_menu} = params

    %{menu: menu} = ExUssd.Utils.navigate("", initial_menu, "session_0011")

    assert length(menu.menu_list) == 3
  end

  test "navigate to Product A", params do
    %{initial_menu: initial_menu} = params

    %{menu: _menu} = ExUssd.Utils.navigate("", initial_menu, "session_002")
    %{menu: menu} = ExUssd.Utils.navigate("1", initial_menu, "session_002")
    assert "selected product a" == menu.title
    assert 0 == length(menu.menu_list)
  end

  test "navigate to the next layer", params do
    %{initial_menu: initial_menu} = params

    %{menu: _menu} = ExUssd.Utils.navigate("", initial_menu, "session_003")
    %{menu: menu} = ExUssd.Utils.navigate("98", initial_menu, "session_003")
    assert "Welcome" == menu.title
    assert 3 == length(menu.menu_list)
  end

  test "navigate back to initial menu", params do
    %{initial_menu: initial_menu} = params

    %{menu: _menu} = ExUssd.Utils.navigate("", initial_menu, "session_004")
    %{menu: _menu} = ExUssd.Utils.navigate("1", initial_menu, "session_004")
    %{menu: menu} = ExUssd.Utils.navigate("0", initial_menu, "session_004")
    assert "Welcome" == menu.title
    assert 3 == length(menu.menu_list)
  end

  test "navigate home", params do
    defmodule ProductAHandler do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu
        |> Map.put(:home, %{name: "HOME", input_match: "00", display_style: ":", enable: true})
        |> Map.put(:title, "selected product a")
      end
    end

    defmodule MyHomeHandler_7 do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu
        |> Map.put(:title, "Welcome")
        |> Map.put(:split, 2)
        |> Map.put(
          :menu_list,
          [
            ExUssd.Menu.render(name: "Product A", handler: ProductAHandler),
            ExUssd.Menu.render(name: "Product B", handler: ProductBHandler),
            ExUssd.Menu.render(name: "Product C", handler: ProductCHandler)
          ]
        )
      end
    end

    initial_menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler_7)

    %{menu: _menu} = ExUssd.Utils.navigate("", initial_menu, "session_005")
    %{menu: _menu} = ExUssd.Utils.navigate("1", initial_menu, "session_005")
    %{menu: menu} = ExUssd.Utils.navigate("00", initial_menu, "session_005")
    assert "Welcome" == menu.title
    assert 3 == length(menu.menu_list)
  end

  test "navigate back to initial menu from nested menu", params do
    %{initial_menu: initial_menu} = params

    %{menu: _menu} = ExUssd.Utils.navigate("", initial_menu, "session_006")
    %{menu: _menu} = ExUssd.Utils.navigate("1", initial_menu, "session_006")
    %{menu: _menu} = ExUssd.Utils.navigate("98", initial_menu, "session_006")
    %{menu: _menu} = ExUssd.Utils.navigate("0", initial_menu, "session_006")
    %{menu: menu} = ExUssd.Utils.navigate("0", initial_menu, "session_006")
    assert "Welcome" == menu.title
    assert 3 == length(menu.menu_list)
  end

  test "navigation not properly started", params do
    %{initial_menu: initial_menu} = params

    assert_raise ArgumentError, fn ->
      ExUssd.Utils.navigate("22", initial_menu, "session_007")
    end
  end

  test "navigate to Product A from nested loop", params do
    %{initial_menu: initial_menu} = params

    %{menu: menu} = ExUssd.Utils.navigate("*141*1#", initial_menu, "session_008", "*141#")
    assert "selected product a" == menu.title
    assert 0 == length(menu.menu_list)
  end

  test "wrong input value from nested loop", params do
    %{initial_menu: initial_menu} = params

    %{menu: menu} = ExUssd.Utils.navigate("*141*12#", initial_menu, "session_008", "*141#")
    assert "Welcome" == menu.title
    assert "Invalid Choice\n" == menu.error
  end
end
