alias ExUssd.Menu

defmodule Example.Components.Exit do
  def exit_menu do
    ExUssd.Menu.render(
        name: "Exit",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
          |> Map.put(:title, "Thank you for using Bank")
          |> Map.put(:should_close, true)
        end
      )
  end
end
