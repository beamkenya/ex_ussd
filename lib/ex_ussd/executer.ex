defmodule ExUssd.Executer do
  @moduledoc """
  This module invokes ExUssd callback functions.
  """

  @doc """
  'execute_navigate/2' function
  It invoke's anonymous function set on navigate field.
  Params:
    - menu: ExUssd struct menu
    - api_parameters: gateway response map
  """

  @spec execute_navigate(ExUssd.t(), map()) :: ExUssd.t()
  def execute_navigate(menu, api_parameters)

  def execute_navigate(%ExUssd{navigate: navigate} = menu, api_parameters)
      when is_function(navigate) do
    case apply(navigate, [menu, api_parameters]) do
      %ExUssd{} = menu -> %{menu | navigate: nil}
      _ -> menu
    end
  end

  def execute_navigate(%ExUssd{} = menu, _), do: menu

  @doc """
   It invoke's the callback function on the resolve field.

  ## Parameters

    - `menu` - ExUssd struct menu
    - `api_parameters` - gateway response map
  """
  @spec execute(ExUssd.t(), map()) :: {:ok, ExUssd.t()}
  def execute(menu, api_parameters)

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

  @doc """
   It invoke's 'ussd_callback/3' callback function on the resolver module.

  ## Parameters

    - `menu` - ExUssd struct menu
    - `api_parameters` - gateway response map
    - `metadata` - ExUssd metadata map
  """

  @spec execute_callback(%ExUssd{}, map(), map()) :: {:ok, ExUssd.t()} | any()
  def execute_callback(menu, api_parameters, metadata)

  def execute_callback(%ExUssd{resolve: resolve} = menu, api_parameters, metadata)
      when is_atom(resolve) do
    if function_exported?(resolve, :ussd_callback, 3) do
      with %ExUssd{error: error} = menu <-
             apply(resolve, :ussd_callback, [menu, api_parameters, metadata]) do
        if(is_bitstring(error), do: {:halt, menu}, else: {:ok, menu})
      end
    end
  end

  def execute_callback(_, _, _), do: nil

  @doc """
   It invoke's 'ussd_after_callback/3' callback function on the resolver module.

  ## Parameters

    - `menu` - ExUssd struct menu
    - `api_parameters` - gateway response map
    - `metadata` - ExUssd metadata map
  """

  @spec execute_after_callback(%ExUssd{}, map(), map()) :: {:ok | :halt, ExUssd.t()} | any()
  def execute_after_callback(menu, api_parameters, metadata)

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
            {:halt, menu}

          is_bitstring(original_error) ->
            {:halt, %{menu | error: original_error}}

          true ->
            {:ok, menu}
        end
      end
    end
  end

  def execute_after_callback(_, _, _), do: nil
end
