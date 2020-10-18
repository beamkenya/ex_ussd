defmodule ExUssd.DisplayTest do
  use ExUnit.Case, async: true

  alias ExUssd.Menu
  alias ExUssd.Utils
  alias ExUssd.Display

  describe "generate menu with title (level 1)" do
    menu =
      Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
          |> Map.put(:title, "Home Page: Welcome")
        end
      )

    home = Utils.call_menu_callback(menu)
    routes = ExUssd.Routes.get_route(%{text: "*544#", service_code: "*544#"})
    # [%{depth: 1, value: "555"}]
    display = Display.generate(menu: home, routes: routes)
    assert "Home Page: Welcome" == display
  end

  describe "generate menu with title and menu_items (level 1)" do
    menu =
      Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
          |> Map.put(:title, "Welcome")
          |> Map.put(
            :menu_list,
            [
              Menu.render(
                name: "child 1",
                handler: fn menu, _api_parameters, _should_handle ->
                  menu
                  |> Map.put(:title, "Welcome to child 1 page")
                end
              ),
              Menu.render(
                name: "child 2",
                handler: fn menu, _api_parameters ->
                  menu
                  |> Map.put(:title, "Welcome to child 2 page")
                end
              )
            ]
          )
        end
      )

    home = Utils.call_menu_callback(menu)
    routes = ExUssd.Routes.get_route(%{text: "*544#", service_code: "*544#"})
    # [%{depth: 1, value: "555"}]
    display = Display.generate(menu: home, routes: routes)
    assert "Welcome\n1:child 1\n2:child 2" == display
  end

  describe "generate menu with title and menu_items with a max of 2 elements on depth 1 (level 1)" do
    menu =
      Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
          |> Map.put(:title, "Welcome")
          |> Map.put(
            :menu_list,
            [
              Menu.render(
                name: "child 1",
                handler: fn menu, _api_parameters, _should_handle ->
                  menu
                  |> Map.put(:title, "Welcome to child 1 page")
                end
              ),
              Menu.render(
                name: "child 2",
                handler: fn menu, _api_parameters, _should_handle ->
                  menu
                  |> Map.put(:title, "Welcome to child 2 page")
                end
              ),
              Menu.render(
                name: "child 3",
                handler: fn menu, _api_parameters, _should_handle ->
                  menu
                  |> Map.put(:title, "Welcome to child 3 page")
                end
              ),
              Menu.render(
                name: "child 4",
                handler: fn menu, _api_parameters, _should_handle ->
                  menu
                  |> Map.put(:title, "Welcome to child 4 page")
                end
              )
            ]
          )
          |> Map.put(:split, 2)
        end
      )

    home = Utils.call_menu_callback(menu)
    routes = ExUssd.Routes.get_route(%{text: "*544#", service_code: "*544#"})
    # [%{depth: 1, value: "555"}]
    display = Display.generate(menu: home, routes: routes)
    assert "Welcome\n1:child 1\n2:child 2\n98:MORE" == display
  end

  describe "generate menu with title and menu_items with a max of 2 elements on depth 2 (level 1)" do
    menu =
      Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
          |> Map.put(:title, "Welcome")
          |> Map.put(
            :menu_list,
            [
              Menu.render(
                name: "child 1",
                handler: fn menu, _api_parameters, _should_handle ->
                  menu
                  |> Map.put(:title, "Welcome to child 1 page")
                end
              ),
              Menu.render(
                name: "child 2",
                handler: fn menu, _api_parameters, _should_handle ->
                  menu
                  |> Map.put(:title, "Welcome to child 2 page")
                end
              ),
              Menu.render(
                name: "child 3",
                handler: fn menu, _api_parameters, _should_handle ->
                  menu
                  |> Map.put(:title, "Welcome to child 3 page")
                end
              ),
              Menu.render(
                name: "child 4",
                handler: fn menu, _api_parameters, _should_handle ->
                  menu
                  |> Map.put(:title, "Welcome to child 4 page")
                end
              )
            ]
          )
          |> Map.put(:split, 2)
        end
      )

    home = Utils.call_menu_callback(menu)
    # ExUssd.Routes.get_route(%{text: "*544#", service_code: "*544#"})
    routes = [%{depth: 2, value: "555"}]
    # [%{depth: 2, value: "555"}]
    display = Display.generate(menu: home, routes: routes)
    assert "Welcome\n3:child 3\n4:child 4\n0:BACK" == display
  end

  describe "generate menu with title and menu_items with a max of 2 elements on depth 1 (level 2)" do
    menu =
      Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
          |> Map.put(:title, "Welcome")
          |> Map.put(
            :menu_list,
            [
              Menu.render(
                name: "child 1",
                handler: fn menu, _api_parameters, _should_handle ->
                  menu
                  |> Map.put(:title, "Welcome to child 1 page")
                end
              ),
              Menu.render(
                name: "child 2",
                handler: fn menu, _api_parameters, _should_handle ->
                  menu
                  |> Map.put(:title, "Welcome to child 2 page")
                end
              ),
              Menu.render(
                name: "child 3",
                handler: fn menu, _api_parameters, _should_handle ->
                  menu
                  |> Map.put(:title, "Welcome to child 3 page")
                end
              ),
              Menu.render(
                name: "child 4",
                handler: fn menu, _api_parameters, _should_handle ->
                  menu
                  |> Map.put(:title, "Welcome to child 4 page")
                end
              )
            ]
          )
          |> Map.put(:split, 2)
        end
      )

    home = Utils.call_menu_callback(menu)
    # ExUssd.Routes.get_route(%{text: "*544#", service_code: "*544#"})
    routes = [%{depth: 1, value: "555"}, %{depth: 1, value: "555"}]
    # [%{depth: 2, value: "555"}]
    display = Display.generate(menu: home, routes: routes)
    assert "Welcome\n1:child 1\n2:child 2\n0:BACK 98:MORE" == display
  end

  describe "generate menu with title and menu_items (level 2)" do
    menu =
      Menu.render(
        name: "child 1",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
          |> Map.put(:title, "Welcome to child 1 page")
          |> Map.put(
            :menu_list,
            [
              Menu.render(
                name: "page 1",
                handler: fn menu, _api_parameters, _should_handle ->
                  menu
                  |> Map.put(:title, "On page 1")
                end
              ),
              Menu.render(
                name: "page 2",
                handler: fn menu, _api_parameters, _should_handle ->
                  menu
                  |> Map.put(:title, "On page 2")
                end
              )
            ]
          )
        end
      )

    home = Utils.call_menu_callback(menu)
    routes = ExUssd.Routes.get_route(%{text: "*544*1#", service_code: "*544#"})
    # [%{depth: 1, value: "1"}, %{depth: 1, value: "555"}]
    display = Display.generate(menu: home, routes: routes)
    assert "Welcome to child 1 page\n1:page 1\n2:page 2\n0:BACK" == display
  end
end
