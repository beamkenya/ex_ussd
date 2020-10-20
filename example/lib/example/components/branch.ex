alias ExUssd.Menu
alias Example.Components.Branch

defmodule Example.Components.Branch do
  def change_branch do
    Menu.render(
      name: "change branch",
      handler: fn menu, _api_parameters, _should_handle ->
        menu
        |> Map.put(:title, "select county")
        |> Map.put(:menu_list, Branch.populate_counties())
    end)
  end

  def populate_counties do
    counties = ["Nakuru", "Nairobi", "Kisii", "Migori", "Kisumu", "Kericho", "Kajiado", "Samburu", "Kiambu", "Makueni", "Machakos", "Meru", "Lamu", "Mombasa"]
    Enum.map(counties, fn country_name -> Branch.country_menu(name: country_name) end)
  end

  def country_menu(name: name) do
    Menu.render(
      name: name,
      handler: fn menu, _api_parameters, _should_handle ->
        menu
        |> Map.put(:title, "#{menu.name}: Select Branch")
        |> Map.put(:menu_list, Branch.branches(country_name: menu.name))
    end)
  end

  def branches(country_name: country_name) do
    branches = ["A", "B", "C", "D", "E"]
    n = Enum.random(1..5)
    country_branches = Enum.take_random(branches, n)
    Enum.map(country_branches, fn branch_name ->
      Menu.render(
        name: "Branch #{branch_name}",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
          |> Map.put(:title, "Do you want to change your bank branch to #{menu.name} - #{country_name}\nPress 1 to confirm.")
          |> Map.put(:handle, true)
          |> Map.put(:validation_menu, Branch.change_branch(%{branch_name: menu.name, country_name: country_name}))
      end)
    end)
  end

  def change_branch(%{branch_name: branch_name, country_name: country_name}) do
      Menu.render(
      name: "back_menu",
      handler: fn menu, api_parameters, should_handle ->
        case should_handle do
          true ->
            cond do
              api_parameters.text == "1" ->
                menu
                |> Map.put(:success, true)
                |> Map.put(:handle, true)
                |> Map.put(:should_close, true)
                |> Map.put(:title, "Successful changed your branch to #{branch_name} - #{country_name}")
              true ->
                menu
                |> Map.put(:error, "Invalid choice\n")
            end
          false -> menu
        end
    end)
  end
end
