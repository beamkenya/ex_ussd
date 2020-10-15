defmodule ExUssd.Utils do
  def call_menu_callback(%ExUssd.Menu{} = menu, %{} = api_parameters \\ %{}) do
    menu.callback.(api_parameters)
  end
end
