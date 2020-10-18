defmodule ExUssd.Utils do
  def call_menu_callback(
        %ExUssd.Menu{} = menu,
        %{} = api_parameters \\ %{},
        should_handle \\ false
      ) do
    menu.callback.(api_parameters, should_handle)
  end
end
