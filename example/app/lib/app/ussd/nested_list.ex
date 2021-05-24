defmodule App.NestedList.ProductCHandler do
  use ExUssd.Handler
  def init(menu, _api_parameters) do
    menu
    |> ExUssd.set(title: "product c")
  end
end

defmodule App.NestedList.ProductBHandler do
  use ExUssd.Handler
  def init(menu, _api_parameters) do
    menu
    |> ExUssd.set(title: "product b")
    |> ExUssd.add(ExUssd.new(name: "Product C", handler: App.NestedList.ProductCHandler))
  end
end

defmodule App.NestedList.ProductAHandler do
  use ExUssd.Handler
  def init(menu, _api_parameters) do
    menu
    |> ExUssd.set(title: "product a")
    |> ExUssd.add(ExUssd.new(name: "Product B", handler: App.NestedList.ProductBHandler))
  end
end

defmodule App.NestedList.MyHomeHandler do
  use ExUssd.Handler
  def init(menu, _api_parameters) do
    menu
    |> ExUssd.set(title: "Nested List")
    |> ExUssd.add(ExUssd.new(name: "Product A", handler: App.NestedList.ProductAHandler))
  end
end
