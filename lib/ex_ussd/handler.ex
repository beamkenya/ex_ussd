defmodule ExUssd.Handler do
  @moduledoc ~S"""
  This module provides callbacks to implement ExUssd handler.
  """

  @doc ~S"""
  ## Examples
      defmodule MyHomeHandler do
        use ExUssd.Handler
        def init(menu, _api_parameters) do
          menu |> ExUssd.set(title: "Enter your pin number")
        end

        def callback(menu, api_parameters) do
          case api_parameters.text == "5555" do
            true ->
              menu
              |> ExUssd.set(title: "success, thank you.")
              |> ExUssd.set(should_close: true)

            _ ->
              menu |> ExUssd.set(error: "Wrong pin number\n")
          end
        end
      end
  """

  @type menu() :: ExUssd.t()
  @type api_parameters() :: map()

  @callback init(
              menu :: menu(),
              api_parameters :: api_parameters()
            ) ::
              menu :: menu()

  @callback navigation_response(payload :: map()) :: payload :: any()

  defmacro __using__([]) do
    quote do
      @behaviour ExUssd.Handler

      @impl ExUssd.Handler
      def navigation_response(response), do: ExUssd.Handler.navigation_response(response)
      defoverridable ExUssd.Handler
    end
  end

  def navigation_response(payload) do
    payload
  end
end
