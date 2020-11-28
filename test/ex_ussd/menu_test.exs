defmodule ExUssd.MenuTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias ExUssd.Menu

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
         _-> menu |> Map.put(:title, "Welcome")
        end
       end
    end

    data = %{language: "Swahili"}
    menu = ExUssd.Menu.render(name: "Home", data: data, handler: MyHomeHandler)
    assert {:ok, %{menu_string: "Karibu", should_close: false}} = ExUssd.simulate(menu: menu, text: "")

  end
end
