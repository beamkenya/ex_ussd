defmodule ExUssd.Example do
  @moduledoc false
  def ussd_init(menu, _) do
    menu
    |> ExUssd.set(title: "Enter your PIN")
  end

  def ussd_callback(menu, api_parameters, _) do
    if api_parameters.text == "5555" do
      menu
      |> ExUssd.set(title: "You have Entered the Secret Number, 5555")
      |> ExUssd.set(should_close: true)
    end
  end

  def simple(menu, _) do
    menu
    |> ExUssd.set(title: "Welcome")
    |> ExUssd.add(
      ExUssd.new(
        name: "menu 1",
        resolve: &simple/2
      )
      |> ExUssd.set(split: 3)
    )
    |> ExUssd.add(
      ExUssd.new(
        name: "menu 2",
        resolve: fn menu, _ -> ExUssd.set(menu, title: "menu 2") end
      )
    )
    |> ExUssd.add(
      ExUssd.new(
        name: "menu 3",
        resolve: fn menu, _ -> ExUssd.set(menu, title: "menu 3") end
      )
    )
    |> ExUssd.add(
      ExUssd.new(
        name: "menu 4",
        resolve: fn menu, _ -> ExUssd.set(menu, title: "menu 4") end
      )
    )
    |> ExUssd.add(
      ExUssd.new(
        name: "menu 5",
        resolve: fn menu, _ -> ExUssd.set(menu, title: "menu 5") end
      )
    )
  end
end
