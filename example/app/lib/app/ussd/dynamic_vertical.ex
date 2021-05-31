defmodule App.Dymanic.Vertical.SubCountyHandler do
  use ExUssd.Handler

  def init(%{data: %{name: name}} = menu, _api_parameters) do
    # TODO: Fetch county sub locations by county_code

    # Make dynamic location menus for the county
    # Split by 6 / 7
    menu
    |> ExUssd.set(title: "#{name} County")
  end
end

defmodule App.Dymanic.Vertical.MyHomeHandler do
  use ExUssd.Handler

  def init(menu, _api_parameters) do
    menus =
      fetch_api()
      |> Enum.map(fn %{name: name} = data ->
        ExUssd.new(name: name, data: data)
      end)

    menu
    |> ExUssd.set(title: "List of Counties")
    |> ExUssd.dynamic(
      menus: menus,
      handler: App.Dymanic.Vertical.SubCountyHandler,
      orientation: :vertical
    )
  end

  def fetch_api do
    [
      %{county_code: 47, name: "Nairobi"},
      %{county_code: 01, name: "Mombasa"},
      %{county_code: 42, name: "Kisumu"}
    ]
  end
end
