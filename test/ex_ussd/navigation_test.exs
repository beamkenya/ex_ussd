defmodule ExUssd.NavigationTest do
  use ExUnit.Case, async: true
  alias ExUssd.State.Registry
  alias ExUssd.Menu
  import ExUssd.Utils

  setup do
    internal_routing = %{session_id: "session_01", service_code: "*544#"}
    Registry.start(internal_routing.session_id)
  end

  test "show the 1 layer" do
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
              )
            ]
          )
        end
      )

    {:ok, menu_string} = simulate(menu: menu, text: "")
    assert menu_string == "Welcome\n1:child 1\n2:child 2"
  end

  test "go to level 2" do
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
              )
            ]
          )
        end
      )

    {:ok, _menu_string} = simulate(menu: menu, text: "")
    {:ok, menu_string} = simulate(menu: menu, text: "1")
    assert menu_string == "Welcome to child 1 page\n0:BACK"
  end

  test "go back 1 layer" do
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
              )
            ]
          )
        end
      )

    {:ok, _menu_string} = simulate(menu: menu, text: "")
    {:ok, _menu_string} = simulate(menu: menu, text: "1")
    {:ok, menu_string} = simulate(menu: menu, text: "0")
    assert menu_string == "Welcome\n1:child 1\n2:child 2"
  end

  test "go 1 level in" do
    menu =
      Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
          |> Map.put(:split, 2)
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
        end
      )

    {:ok, _menu_string} = simulate(menu: menu, text: "")
    {:ok, menu_string} = simulate(menu: menu, text: "98")
    assert menu_string == "Welcome\n3:child 3\n4:child 4\n0:BACK"
  end

  test "go back 1 level" do
    menu =
      Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
          |> Map.put(:split, 2)
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
        end
      )

    {:ok, _menu_string} = simulate(menu: menu, text: "")

    {:ok, _menu_string} = simulate(menu: menu, text: "98")

    {:ok, menu_string} = simulate(menu: menu, text: "0")
    assert menu_string == "Welcome\n1:child 1\n2:child 2\n98:MORE"
  end

  test "validate client input" do
    menu =
      Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
          |> Map.put(:title, "Enter Pin Number")
          |> Map.put(:handle, true)
          |> Map.put(
            :validation_menu,
            Menu.render(
              name: "",
              handler: fn menu, api_parameters, should_handle ->
                case should_handle do
                  true ->
                    case api_parameters.text == "5342" do
                      true ->
                        menu
                        |> Map.put(:title, "Welcome Back")
                        |> Map.put(:success, true)

                      _ ->
                        menu |> Map.put(:error, "Invalid Pin Number")
                    end

                  false ->
                    menu
                end
              end
            )
          )
        end
      )

    {:ok, _menu_string} = simulate(menu: menu, text: "")

    {:ok, menu_string} = simulate(menu: menu, text: "5342")

    assert menu_string == "Welcome Back\n0:BACK"
  end
end
