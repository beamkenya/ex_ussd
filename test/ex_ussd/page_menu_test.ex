defmodule ExUssdTest.PageMenuTest do
  use ExUnit.Case
  doctest ExUssd
  doctest AfricasTalking
  doctest Infobip
  doctest ExUssd.Utils

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

    defmodule PageMenuHandler do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu
        |> Map.put(:page_menu, true)
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

    menu = ExUssd.Menu.render(name: "Home", handler: PageMenuHandler)
    session = "session_1000124"
    %{menu: response_menu} = ExUssd.Utils.navigate("", menu, session)
    get_menu = ExUssd.get_menu(session_id: session)

    %{
      current_menu: get_menu
    }
  end

  test "test menu get menu", %{menu: menu} do
    assert "" == menu
  end
end
