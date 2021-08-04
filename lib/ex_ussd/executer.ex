defmodule ExUssd.Executer do
  @moduledoc """
  This module provides the executer for the USSD lib.
  """

  def execute_navigate(%ExUssd{navigate: navigate} = menu, api_parameters)
      when is_function(navigate, 2) do
    case apply(navigate, [menu, api_parameters]) do
      %ExUssd{} = menu -> %{menu | navigate: nil}
      _ -> menu
    end
  end

  def execute_navigate(menu, _), do: menu

  def execute(%ExUssd{resolve: resolve} = menu, api_parameters)
      when is_function(resolve) do
    if is_function(resolve, 2) do
      with %ExUssd{} = menu <- apply(resolve, [menu, api_parameters]), do: {:ok, menu}
    else
      raise %BadArityError{function: resolve, args: [menu, api_parameters]}
    end
  end

  def execute(%ExUssd{name: name, resolve: resolve} = menu, api_parameters) do
    if function_exported?(resolve, :ussd_init, 2) do
      with %ExUssd{} = menu <- apply(resolve, :ussd_init, [menu, api_parameters]),
           do: {:ok, menu}
    else
      raise %ArgumentError{message: "resolve module for #{name} does not export ussd_init/2"}
    end
  end

  def execute_callback(%ExUssd{resolve: resolve} = menu, api_parameters, metadata)
      when is_atom(resolve) do
    if function_exported?(resolve, :ussd_callback, 3) do
      with %ExUssd{error: error} = menu <-
             apply(resolve, :ussd_callback, [menu, api_parameters, metadata]) do
        if(is_bitstring(error), do: {:skip, menu}, else: {:ok, menu})
      end
    end
  end

  def execute_callback(_, _, _), do: nil

  def execute_after_callback(
        %ExUssd{error: original_error, resolve: resolve} = menu,
        api_parameters,
        metadata
      )
      when is_atom(resolve) do
    if function_exported?(resolve, :ussd_after_callback, 3) do
      with %ExUssd{error: error} = menu <-
             apply(resolve, :ussd_after_callback, [%{menu | error: nil}, api_parameters, metadata]) do
        cond do
          is_bitstring(error) ->
            {:skip, menu}

          is_bitstring(original_error) ->
            {:skip, %{menu | error: original_error}}

          true ->
            {:ok, menu}
        end
      end
    end
  end

  def execute_after_callback(_, _, _), do: nil
end
