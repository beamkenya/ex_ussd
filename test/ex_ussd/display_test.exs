defmodule ExUssd.DisplayTest do
  @moduledoc false
  use ExUnit.Case
  alias ExUssd.Display

  setup do
    resolve = fn menu, _api_parameters, _metadata -> menu end

    menu =
      ExUssd.new(name: Faker.Company.name(), resolve: resolve)
      |> ExUssd.set(title: "Welcome")
      |> ExUssd.add(ExUssd.new(name: "menu 1"))
      |> ExUssd.add(ExUssd.new(name: "menu 2"))
      |> ExUssd.add(ExUssd.new(name: "menu 3"))

    route = ExUssd.Route.get_route(%{text: "*544#", service_code: "*544#"})
    %{menu: menu, route: route}
  end

  describe "to_string/3" do
    test "successfully converts ExUssd menu struct into display string", %{
      menu: menu,
      route: route
    } do
      assert {:ok, %{menu_string: "Welcome\n1:menu 1\n2:menu 2\n3:menu 3", should_close: false}} ==
               Display.to_string(menu, route)
    end

    test "successfully converts ExUssd :horizontal menu struct into display string", %{menu: menu} do
      menu = Map.put(menu, :orientation, :horizontal)

      assert {:ok, %{menu_string: "1:3\nmenu 1\n00:HOME\nBACK:0 MORE:98", should_close: false}} ==
               Display.to_string(menu, %{route: [%{depth: 1, text: "1"}]})
    end
  end
end
