defmodule PhoenixApp.MyHomeHandler do
  use ExUssd.Handler

  def init(menu, _api_parameters, metadata) do
    IO.inspect(metadata, label: "metadata")

    menu
    |> ExUssd.set(title: "Examples")
    |> ExUssd.add(ExUssd.new(name: "Simple List", handler: App.SimpleList.MyHomeHandler))
    |> ExUssd.add(ExUssd.new(name: "Nested List", handler: App.NestedList.MyHomeHandler))
    |> ExUssd.add(ExUssd.new(name: "Simple Callback", handler: App.SimpleCallback.MyHomeHandler))
    |> ExUssd.add(ExUssd.new(name: "Nested Callback", handler: App.NestedCallback.PinHandler))
    |> ExUssd.add(
      ExUssd.new(name: "Dynamic Vertical menus", handler: App.Dymanic.Vertical.MyHomeHandler)
    )
    |> ExUssd.add(
      ExUssd.new(name: "Dynamic Horizontal menus", handler: App.Dymanic.Horizontal.MyHomeHandler)
    )
  end

  def after_route(%{menu: menu} = payload) do
    menu
    |> ExUssd.navigate(handler: App.SimpleCallback.MyHomeHandler)
    |> IO.inspect()
  end

  def after_route(%{payload: payload}) do
    IO.inspect(payload)
  end
end
