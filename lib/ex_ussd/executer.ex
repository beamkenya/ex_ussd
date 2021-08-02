defmodule ExUssd.Executer do
  @moduledoc """
  This module provides the executer for the USSD lib.
  """

  def execute(%ExUssd{resolve: resolve} = menu, api_parameters, metadata)
      when is_function(resolve) do
    if is_function(resolve, 3) do
      {:ok, apply(resolve, [menu, api_parameters, metadata])}
    else
      raise %BadArityError{function: resolve, args: [menu, api_parameters, metadata]}
    end
  end

  def execute(%ExUssd{name: name, resolve: resolve} = menu, api_parameters, metadata) do
    if function_exported?(resolve, :ussd_init, 3) do
      {:ok, apply(resolve, :ussd_init, [menu, api_parameters, metadata])}
    else
      raise %ArgumentError{message: "resolve module for #{name} does not export ussd_init/3"}
    end
  end

  def execute_callback(%ExUssd{resolve: resolve} = menu, api_parameters, metadata) do
    if function_exported?(resolve, :ussd_callback, 3) do
      {:skip, apply(resolve, :ussd_callback, [menu, api_parameters, metadata])}
    end
  end

  def execute_after_callback(%ExUssd{resolve: resolve} = menu, api_parameters, metadata) do
    if function_exported?(resolve, :ussd_after_callback, 3) do
      {:ok, apply(resolve, :ussd_after_callback, [menu, api_parameters, metadata])}
    end
  end
end
