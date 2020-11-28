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
      api_parameters: %{text: ""},
      initial_menu: initial_menu
    }
  end

  test "navigate to the initial menu", params do
    %{initial_menu: initial_menu} = params

    menu = simulate("", initial_menu, params)

    assert length(menu.menu_list) == 3
  end

  test "navigate to Product A", params do
    %{initial_menu: initial_menu} = params

    _menu = simulate("", initial_menu, params)
    menu = simulate("1", initial_menu, params)
    assert "selected product a" == menu.title
    assert 0 == length(menu.menu_list)
  end

  test "navigate to the next layer", params do
    %{initial_menu: initial_menu} = params

    _menu = simulate("", initial_menu, params)
    menu = simulate("98", initial_menu, params)
    assert "Welcome" == menu.title
    assert 3 == length(menu.menu_list)
  end

  test "navigate back to initial menu", params do
    %{initial_menu: initial_menu} = params

    _menu = simulate("", initial_menu, params)
    _menu = simulate("1", initial_menu, params)
    menu = simulate("0", initial_menu, params)
    assert "Welcome" == menu.title
    assert 3 == length(menu.menu_list)
  end

  def simulate(text, initial_menu, %{
        session_id: session_id
      }) do

      internal_routing = %{text: text, session_id: session_id, service_code: "*544#"}

      api_parameters = %{"text" => internal_routing.text}

      route =
        ExUssd.Routes.get_route(%{
          text: internal_routing.text,
          service_code: internal_routing.service_code
        })

      %{menu: menu} =
        EXUssd.Common.goto(
          internal_routing: internal_routing,
          menu: initial_menu,
          api_parameters: api_parameters,
          route: route
        )
    menu
  end
end
