defmodule ExUssd.Handler do
  @moduledoc ~S"""
  This module provides callbacks to implement ExUssd menu handler.
  """

  @doc ~S"""
  Callback for event handling.

  This callback takes an menu struct, an api_parameters data and should_handle boolean as the input.

  ## Examples
      defmodule MyHomeHandler do
        @behaviour ExUssd.Handler
        def handle_menu(menu, api_parameters, should_handle) do
          menu |> Map.put(:title, "Welcome")
        end
      end
  """
  @type menu() :: ExUssd.Menu
  @type api_parameters() :: map()
  @type should_handle() :: boolean()

  @callback handle_menu(
              menu :: menu(),
              api_parameters :: api_parameters(),
              should_handle :: should_handle()
            ) ::
              menu :: menu()
end
