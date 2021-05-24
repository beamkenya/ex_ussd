defmodule App.SimpleList.ProductAHandler do
  use ExUssd.Handler
  def init(menu, _api_parameters) do
    menu |> ExUssd.set(title: "selected product a")
  end
end

defmodule App.SimpleList.ProductBHandler do
  use ExUssd.Handler
  def init(menu, _api_parameters) do
    menu |> ExUssd.set(title: "selected product b")
  end
end

defmodule App.SimpleList.ProductCHandler do
  use ExUssd.Handler
  def init(menu, _api_parameters) do
    menu
    |> ExUssd.set(title: "selected product c")
  end
end

defmodule App.SimpleList.MyHomeHandler do
  use ExUssd.Handler
  def init(menu, _api_parameters) do
    menu
    |> ExUssd.set(title: "Simple Menu List")
    |> ExUssd.add(ExUssd.new(name: "Product A", handler: App.SimpleList.ProductAHandler))
    |> ExUssd.add(ExUssd.new(name: "Product B", handler: App.SimpleList.ProductBHandler))
    |> ExUssd.add(ExUssd.new(name: "Product C", handler: App.SimpleList.ProductCHandler))
  end

  def navigation_response(payload) do
    IO.inspect payload
  end
end
