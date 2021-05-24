defmodule App.SimpleCallback.MyHomeHandler do
  use ExUssd.Handler
  def init(menu, _api_parameters) do
    menu
    |> ExUssd.set(title: "Input 5555, for secret Menu")
    |> ExUssd.add(ExUssd.new(name: "Product A", handler: App.SimpleList.ProductAHandler))
    |> ExUssd.add(ExUssd.new(name: "Product B", handler: App.SimpleList.ProductBHandler))
    |> ExUssd.add(ExUssd.new(name: "Product C", handler: App.SimpleList.ProductCHandler))
  end

  def callback(menu, api_parameters) do
    case api_parameters.text == "5555" do
      true ->
        menu
        |> ExUssd.set(title: "You have Entered the Secret Number, 5555")
        |> ExUssd.set(should_close: true)
        |> ExUssd.set(continue: true)

      _ ->
        menu
        |> ExUssd.set(continue: false)
    end
  end
end
