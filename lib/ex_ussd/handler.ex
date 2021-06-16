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

        def before_route(menu, api_parameters) do
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
  @type metadata() :: map()
  @type payload_value() :: %{menu: menu(), api_parameters: api_parameters}
  @type payload() :: {:ok, payload_value()} | {:error, payload_value()}

  @callback init(
              menu :: menu(),
              api_parameters :: api_parameters()
            ) :: menu()
  @callback init(
              menu :: menu(),
              api_parameters :: api_parameters(),
              metadata :: map()
            ) :: menu()

  @callback callback(
              menu :: menu() | map(),
              api_parameters :: api_parameters()
            ) :: menu()

  @callback callback(
              menu :: menu(),
              api_parameters :: api_parameters(),
              metadata :: metadata()
            ) :: menu()

  @callback after_route(payload()) :: any()

  @optional_callbacks init: 2, init: 3, callback: 2, callback: 3, after_route: 1

  defmacro __using__([]) do
    quote do
      @behaviour ExUssd.Handler
    end
  end
end
