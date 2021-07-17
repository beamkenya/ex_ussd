defmodule ExUssd.Handler do
  @moduledoc ~S"""
  This module provides callbacks to implement ExUssd handler.
  """

  @type menu() :: ExUssd.t()
  @type api_parameters() :: map()
  @type metadata() :: map()

  @callback ussd_init(
              menu :: menu(),
              api_parameters :: api_parameters()
            ) :: menu()
  @callback ussd_init(
              menu :: menu(),
              api_parameters :: api_parameters(),
              metadata :: map()
            ) :: menu()

  @callback ussd_callback(
              menu :: menu() | map(),
              api_parameters :: api_parameters()
            ) :: menu()

  @callback ussd_callback(
              menu :: menu(),
              api_parameters :: api_parameters(),
              metadata :: metadata()
            ) :: menu()

  @callback ussd_after_callback(map()) :: any()

  @optional_callbacks ussd_init: 2,
                      ussd_init: 3,
                      ussd_callback: 2,
                      ussd_callback: 3,
                      ussd_after_callback: 1

  defmacro __using__([]) do
    quote do
      @behaviour ExUssd.Handler
    end
  end
end
