defmodule ExUssd.Executer do
  @moduledoc """
  This module provides the executer for the USSD lib.
  """

  def execute(%ExUssd{resolve: resolve} = menu, api_parameters, metadata)
      when is_function(resolve) do
    if is_function(resolve, 3) do
      with %ExUssd{} = menu <- apply(resolve, [menu, api_parameters, metadata]), do: {:ok, menu}
    else
      raise %BadArityError{function: resolve, args: [menu, api_parameters, metadata]}
    end
  end

  def execute(%ExUssd{name: name, resolve: resolve} = menu, api_parameters, metadata)
      when is_atom(resolve) do
    if function_exported?(resolve, :ussd_init, 3) do
      with %ExUssd{} = menu <- apply(resolve, :ussd_init, [menu, api_parameters, metadata]),
           do: {:ok, menu}
    else
      raise %ArgumentError{message: "resolve module for #{name} does not export ussd_init/3"}
    end
  end

  def execute_callback(%ExUssd{resolve: resolve} = menu, api_parameters, metadata)
      when is_atom(resolve) do
    if function_exported?(resolve, :ussd_callback, 3) do
      with %ExUssd{} = menu <- apply(resolve, :ussd_callback, [menu, api_parameters, metadata]),
           do: {:skip, menu}
    end
  end

  def execute_callback(_, _, _), do: nil

  def execute_after_callback(%ExUssd{resolve: resolve} = menu, api_parameters, metadata)
      when is_atom(resolve) do
    if function_exported?(resolve, :ussd_after_callback, 3) do
      with %ExUssd{} = menu <-
             apply(resolve, :ussd_after_callback, [menu, api_parameters, metadata]),
           do: {:skip, menu}
    end
  end

  def execute_after_callback(_, _, _), do: nil
end
