defmodule App.Dymanic.Vertical.SubCountyHandler do
  use ExUssd.Handler
  def init(%{data: %{name: name}}= menu, _api_parameters) do
    # TODO: Fetch county sub locations by county_code

    # Make dynamic location menus for the county
    # Split by 6 / 7
    menu
    |> ExUssd.set(title: "#{name} County")
  end
end

defmodule App.Dymanic.Vertical.CountyHandler do
  use ExUssd.Handler
  def init(menu, _api_parameters) do
    menus = [
      ExUssd.new(name: "Nairobi", data: %{county_code: 47, name: "Nairobi"}),
      ExUssd.new(name: "Mombasa", data: %{county_code: 01, name: "Mombasa"}),
      ExUssd.new(name: "Kisumu", data: %{county_code: 42, name: "Kisumu"})
    ]

    menu
    |> ExUssd.set(title: "List of Counties")
    |> ExUssd.dynamic(menus: menus, handler: App.Dymanic.Vertical.SubCountyHandler, orientation: :vertical)
  end
end

defmodule App.Dymanic.Vertical.MyHomeHandler do
  use ExUssd.Handler
  def init(menu, _api_parameters) do
    menu
    |> ExUssd.set(title: "Dymanic Vertical")
    |> ExUssd.add(ExUssd.new(name: "Counties List", handler: App.Dymanic.Vertical.CountyHandler))
  end
end
