defmodule ExUssd.DisplayTest do
  use ExUnit.Case, async: true

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
  end

  describe "generate menu with title only" do
    defmodule MyHomeHandler_1 do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu |> Map.put(:title, "Welcome")
      end
    end

    initial_menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler_1)
    menu = ExUssd.Utils.call_menu_callback(initial_menu)
    routes = ExUssd.Routes.get_route(%{text: "*544#", service_code: "*544#"})

    assert {:ok, "Welcome"} == ExUssd.Display.generate(menu: menu, routes: routes)
  end

  describe "generate menu with title and menu_list" do
    defmodule MyHomeHandler_2 do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu
        |> Map.put(:title, "Welcome")
        |> Map.put(
          :menu_list,
          [
            ExUssd.Menu.render(name: "Product A", handler: ProductAHandler),
            ExUssd.Menu.render(name: "Product B", handler: ProductBHandler)
          ]
        )
      end
    end

    initial_menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler_2)
    menu = ExUssd.Utils.call_menu_callback(initial_menu)
    routes = ExUssd.Routes.get_route(%{text: "*544#", service_code: "*544#"})

    assert {:ok, "Welcome\n1:Product A\n2:Product B"} ==
             ExUssd.Display.generate(menu: menu, routes: routes)
  end

  describe "generate menu navigation menu on first menu" do
    defmodule MyHomeHandler_3 do
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

    initial_menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler_3)
    menu = ExUssd.Utils.call_menu_callback(initial_menu)
    routes = ExUssd.Routes.get_route(%{text: "*544#", service_code: "*544#"})

    assert {:ok, "Welcome\n1:Product A\n2:Product B\n98:MORE"} ==
             ExUssd.Display.generate(menu: menu, routes: routes)
  end

  describe "generate menu navigation menu on second menu" do
    defmodule MyHomeHandler_4 do
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

    initial_menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler_4)
    menu = ExUssd.Utils.call_menu_callback(initial_menu)
    routes = ExUssd.Routes.get_route(%{text: "*544*2#", service_code: "*544#"})

    assert {:ok, "Welcome\n1:Product A\n2:Product B\n0:BACK 98:MORE"} ==
             ExUssd.Display.generate(menu: menu, routes: routes)
  end

  describe "Hide navigation with menu_list" do
    defmodule MyHomeHandler_5 do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu
        |> Map.put(:title, "Welcome")
        |> Map.put(:split, 2)
        |> Map.put(:show_navigation, false)
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

    initial_menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler_5)
    menu = ExUssd.Utils.call_menu_callback(initial_menu)
    routes = ExUssd.Routes.get_route(%{text: "*544#", service_code: "*544#"})

    assert {:ok, "Welcome\n1:Product A\n2:Product B"} ==
             ExUssd.Display.generate(menu: menu, routes: routes)
  end

  describe "hide navigation menu on second menu" do
    defmodule ProductAHandler do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu
        |> Map.put(:show_navigation, false)
        |> Map.put(:title, "selected product a")
      end
    end

    defmodule MyHomeHandler_6 do
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

    initial_menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler_6)
    _menu = ExUssd.Utils.navigate("", initial_menu, "session_001")
    %{display: menu_string} = ExUssd.Utils.navigate("1", initial_menu, "session_001")
    response = {:ok, menu_string}
    assert {:ok, "selected product a"} == response
  end
end
