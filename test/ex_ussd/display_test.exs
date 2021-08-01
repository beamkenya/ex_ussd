defmodule ExUssd.DisplayTest do
  @moduledoc false
  use ExUnit.Case
  alias ExUssd.{Display, Executer}

  describe "to_string/3" do
    setup do
      route = ExUssd.Route.get_route(%{text: "*544#", service_code: "*544#"})

      resolve = fn menu, _api_parameters, _metadata ->
        menu
        |> ExUssd.set(title: "Welcome")
        |> ExUssd.add(ExUssd.new(name: "menu 1"))
        |> ExUssd.add(ExUssd.new(name: "menu 2"))
      end

      menu = ExUssd.new(name: Faker.Company.name(), resolve: resolve)

      %{menu: menu, route: route}
    end

    test "successfully converts ExUssd menu struct into display string", %{
      menu: menu,
      route: route
    } do
      menu = get_menu(menu)

      assert {:ok, %{menu_string: "Welcome\n1:menu 1\n2:menu 2", should_close: false}} ==
               Display.to_string(menu, route)
    end
  end

  defp get_menu(menu) do
    Executer.execute(menu, Map.new(), Map.new())
  end
end
