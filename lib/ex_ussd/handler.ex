defmodule ExUssd.Handler do
  @moduledoc ~S"""
  This module provides callbacks to implement ExUssd menu handler.
  """

  @doc ~S"""
  Callback for event handling.

  This callback takes an menu struct, and api_parameters data as the input.

  ## Examples
      defmodule MyHomeHandler do
        @behaviour ExUssd.Handler
        def handle_menu(menu, api_parameters) do
          menu |> Map.put(:title, "Welcome")
        end
      end
  """
  @type menu() :: any()
  @type api_parameters() :: map()

  @callback handle_menu(
              menu :: menu(),
              api_parameters :: api_parameters()
            ) ::
              menu :: menu()
end
