defmodule App.NestedCallback.PinHandler do
  use ExUssd.Handler
  def init(menu, _api_parameters) do
    menu
    |> ExUssd.set(title: "Enter your pin number\nhint: 4321")
    |> ExUssd.set(show_navigation: false)
  end

  def callback(menu, api_parameters) do
    case api_parameters.text == "4321" do
      true ->
        menu
        # |> ExUssd.navigate(data: %{name: "John"}, handler: MyHomeHandler)
        |> ExUssd.navigate(handler: App.SimpleCallback.MyHomeHandler)
        |> ExUssd.set(continue: true)
      _ ->
        menu
        |> ExUssd.set(error: "Wrong pin number\n")
        |> ExUssd.set(continue: false)
    end
  end

  def navigation_response(payload) do
    IO.inspect payload
  end
end
