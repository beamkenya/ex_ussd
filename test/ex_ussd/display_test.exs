defmodule ExUssd.DisplayTest do
  @moduledoc false
  use ExUnit.Case
  alias ExUssd.Display

  setup do
    resolve = fn menu, _payload, _metadata -> menu end

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

    test "successfully converts ExUssd zero based menu struct into display string", %{
      menu: menu,
      route: route
    } do
      menu = Map.put(menu, :is_zero_based, true)

      assert {:ok, %{menu_string: "Welcome\n0:menu 1\n1:menu 2\n2:menu 3", should_close: false}} ==
               Display.to_string(menu, route)
    end

    test "successfully converts ExUssd :horizontal zero based menu struct into display string", %{
      menu: menu
    } do
      menu = menu |> Map.put(:orientation, :horizontal) |> Map.put(:is_zero_based, true)

      assert {:ok, %{menu_string: "1:3\nmenu 1\nMORE:98", should_close: false}} ==
               Display.to_string(menu, %{route: [%{depth: 1, text: "1"}]})
    end

    test "successfully converts ExUssd :horizontal menu struct into display string", %{menu: menu} do
      menu = Map.put(menu, :orientation, :horizontal)

      assert {:ok, %{menu_string: "1:3\nmenu 1\nMORE:98", should_close: false}} ==
               Display.to_string(menu, %{route: [%{depth: 1, text: "1"}]})
    end

    test "successfully converts ExUssd :horizontal menu struct into display string (nest 2)", %{
      menu: menu
    } do
      menu = Map.put(menu, :orientation, :horizontal)

      assert {:ok, %{menu_string: "2:3\nmenu 2\nBACK:0 MORE:98", should_close: false}} ==
               Display.to_string(menu, %{route: [%{depth: 2, text: "1"}]})
    end

    test "successfully converts ExUssd :horizontal menu struct into display string (nest 3)", %{
      menu: menu
    } do
      menu = Map.put(menu, :orientation, :horizontal)

      assert {:ok, %{menu_string: "3:3\nmenu 3\nBACK:0", should_close: false}} ==
               Display.to_string(menu, %{route: [%{depth: 3, text: "1"}]})
    end

    test "successfully converts ExUssd :horizontal menu struct into display string (level 1)", %{
      menu: menu
    } do
      menu = Map.put(menu, :orientation, :horizontal)

      assert {:ok, %{menu_string: "1:3\nmenu 1\n00:HOME\nBACK:0 MORE:98", should_close: false}} ==
               Display.to_string(menu, %{
                 route: [%{depth: 1, text: "1"}, %{depth: 1, text: "5555"}]
               })
    end
  end
end
