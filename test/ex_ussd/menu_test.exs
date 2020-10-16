defmodule ExUssd.MenuTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias ExUssd.Menu

  describe "test menu structure on render" do
    menu =
      Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
          |> Map.put(:title, "Home Page: Welcome")
        end
      )

    assert is_function(menu.callback)
    assert is_function(menu.handler)
    assert menu.title == nil
  end
end
