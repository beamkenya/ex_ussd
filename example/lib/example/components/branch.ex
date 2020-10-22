alias ExUssd.Menu
alias Example.Components.Branch

defmodule Example.Components.Branch do
  def change_branch do
    Menu.render(
      name: "change branch",
      handler: fn menu, _api_parameters, _should_handle ->
        menu
        |> Map.put(:title, "select county")
        |> Map.put(:menu_list, populate_counties())
      end
    )
  end

  def populate_counties do
    counties = [
      "Nakuru",
      "Nairobi",
      "Kisii",
      "Migori",
      "Kisumu",
      "Kericho",
      "Kajiado",
      "Samburu",
      "Kiambu",
      "Makueni",
      "Machakos",
      "Meru",
      "Lamu",
      "Mombasa"
    ]

    Enum.map(counties, fn country_name ->
      ExUssd.Menu.render(
        name: country_name,
        data: %{country_name: country_name},
        handler: fn menu, _api_parameters, _should_handle ->
          %{country_name: country_name} = menu.data

          menu
          |> Map.put(:title, "#{country_name}: Select Branch")
          |> Map.put(:menu_list, populate_branches(country_name: country_name))
        end
      )
    end)
  end

  def populate_branches(country_name: country_name) do
    branches = simulate_api_call()

    Enum.map(branches, fn branch_name ->
      Menu.render(
        name: "Branch #{branch_name}",
        data: %{country_name: country_name, branch_name: branch_name},
        handler: fn menu, _api_parameters, _should_handle ->
          %{country_name: country_name, branch_name: branch_name} = menu.data

          menu
          |> Map.put(
            :title,
            "change your branch to Branch #{branch_name} - #{country_name}\nPress 1 to confirm."
          )
          |> Map.put(:handle, true)
          |> Map.put(
            :validation_menu,
            Branch.change_branch(%{branch_name: menu.name, country_name: country_name})
          )
        end
      )
    end)
  end

  def simulate_api_call do
    n = Enum.random(1..5)
    Enum.take_random(["A", "B", "C", "D", "E"], n)
  end

  def change_branch(%{branch_name: branch_name, country_name: country_name}) do
    Menu.render(
      name: "change branch",
      handler: fn menu, api_parameters, should_handle ->
        case should_handle do
          true ->
            cond do
              api_parameters.text == "1" ->
                menu
                |> Map.put(:success, true)
                |> Map.put(:handle, true)
                |> Map.put(:should_close, true)
                |> Map.put(
                  :title,
                  "Successful changed branch to Branch #{branch_name} - #{country_name}"
                )

              true ->
                menu
                |> Map.put(:error, "Invalid choice\n")
            end

          false ->
            menu
        end
      end
    )
  end
end
