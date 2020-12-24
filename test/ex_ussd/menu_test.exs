defmodule ExUssd.MenuTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias ExUssd.Menu

  setup do
    defmodule ProductAHandler11 do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu |> Map.put(:title, "selected product a")
      end
    end

    defmodule ProductBHandler11 do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu |> Map.put(:title, "selected product b")
      end
    end

    defmodule ProductCHandler11 do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu
        |> Map.put(:title, "selected product c")
        |> Map.put(:should_close, true)
      end
    end

    defmodule MyHomeHandler11 do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu
        |> Map.put(:page_menu, true)
        |> Map.put(
          :menu_list,
          [
            ExUssd.Menu.render(name: "Product A", handler: ProductAHandler11),
            ExUssd.Menu.render(name: "Product B", handler: ProductBHandler11),
            ExUssd.Menu.render(name: "Product C", handler: ProductCHandler11)
          ]
        )
      end
    end

    initial_menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler11)
    %{
      initial_menu: initial_menu
    }
  end

  describe "test menu structure on render" do
    menu =
      Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters ->
          menu
          |> Map.put(:title, "Home Page: Welcome")
        end
      )

    assert is_function(menu.callback)
    assert is_function(menu.handler)
    assert menu.title == nil
  end

  describe "test menu with data prop" do
    defmodule MyHomeHandler do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        %{language: language} = menu.data

        case language do
          "Swahili" -> menu |> Map.put(:title, "Karibu")
          _ -> menu |> Map.put(:title, "Welcome")
        end
      end
    end

    data = %{language: "Swahili"}
    menu = ExUssd.Menu.render(name: "Home", data: data, handler: MyHomeHandler)

    assert {:ok, %{menu_string: "Karibu", should_close: false}} =
             ExUssd.simulate(menu: menu, text: "")
  end

  test "return the first element", params do
    %{initial_menu: initial_menu} = params
    assert {:ok, %{menu_string: "selected product a", should_close: false}} = ExUssd.simulate(menu: initial_menu, text: "")
  end

  test "navigate to the second element (98)", params do
    %{initial_menu: initial_menu} = params
    ExUssd.simulate(menu: initial_menu, text: "")
    assert {:ok, %{menu_string: "selected product b", should_close: false}} = ExUssd.simulate(menu: initial_menu, text: "98")
  end

  test "navigate back to the first element (0)", params do
    %{initial_menu: initial_menu} = params
    ExUssd.simulate(menu: initial_menu, text: "")
    ExUssd.simulate(menu: initial_menu, text: "98")
    assert {:ok, %{menu_string: "selected product a", should_close: false}} = ExUssd.simulate(menu: initial_menu, text: "0")
  end

  test "navigate to the first element (1)", params do
    %{initial_menu: initial_menu} = params
    ExUssd.simulate(menu: initial_menu, text: "")
    assert {:ok, %{menu_string: "selected product a", should_close: false}} = ExUssd.simulate(menu: initial_menu, text: "1")
  end

  test "navigate to the second element (2)", params do
    %{initial_menu: initial_menu} = params
    ExUssd.simulate(menu: initial_menu, text: "")
    assert {:ok, %{menu_string: "selected product b", should_close: false}} = ExUssd.simulate(menu: initial_menu, text: "2")
  end

  test "navigate to the third element (3)", params do
    %{initial_menu: initial_menu} = params
    ExUssd.simulate(menu: initial_menu, text: "")
    assert {:ok, %{menu_string: "selected product c", should_close: true}} = ExUssd.simulate(menu: initial_menu, text: "3")
  end
end
