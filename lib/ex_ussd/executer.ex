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

  alias ExUssd.Utils

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
   It invoke's the init callback function on the resolve field.

  ## Parameters

    - `menu` - ExUssd struct menu
    - `api_parameters` - gateway response map
  """
  @spec execute_init_callback(ExUssd.t(), map()) :: {:ok, ExUssd.t()}
  def execute_init_callback(menu, api_parameters)

  def execute_init_callback(%ExUssd{resolve: resolve} = menu, api_parameters)
      when is_function(resolve) do
    if is_function(resolve, 2) do
      with %ExUssd{} = menu <- apply(resolve, [menu, api_parameters]), do: {:ok, menu}
    else
      raise %BadArityError{function: resolve, args: [menu, api_parameters]}
    end
  end

  def execute_init_callback(%ExUssd{name: name, resolve: resolve} = menu, api_parameters) do
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
  """

  @spec execute_callback(%ExUssd{}, map()) :: {:ok, ExUssd.t()} | any()
  def execute_callback(menu, api_parameters)

  def execute_callback(%ExUssd{navigate: navigate} = menu, api_parameters)
      when not is_nil(navigate) do
    menu
    |> Map.put(:resolve, navigate)
    |> Map.delete(:navigate)
    |> execute_init_callback(api_parameters)
  end

  def execute_callback(%ExUssd{resolve: resolve} = menu, api_parameters)
      when is_atom(resolve) do
    if function_exported?(resolve, :ussd_callback, 3) do
      metadata = Utils.fetch_metadata(api_parameters)

      with %ExUssd{error: error} = current_menu <-
             apply(resolve, :ussd_callback, [%{menu | resolve: nil}, api_parameters, metadata]) do
        if is_bitstring(error) do
          build_response_menu(:halt, current_menu, menu, api_parameters)
        else
          build_response_menu(:ok, current_menu, menu, api_parameters)
        end
      end
      |> case do
        {:ok, %ExUssd{resolve: resolve} = menu} when not is_nil(resolve) ->
          execute_init_callback(menu, api_parameters)

        result ->
          result
      end
    end
  end

  def execute_callback(_menu, _api_parameters), do: nil

  @doc """
   It invoke's 'ussd_after_callback/3' callback function on the resolver module.

  ## Parameters

    - `menu` - ExUssd struct menu
    - `api_parameters` - gateway response map
  """

  @spec execute_after_callback(%ExUssd{}, map()) :: {:ok | :halt, ExUssd.t()} | any()
  def execute_after_callback(menu, api_parameters)

  def execute_after_callback(
        %ExUssd{error: original_error, resolve: resolve} = menu,
        api_parameters
      )
      when is_atom(resolve) do
    if function_exported?(resolve, :ussd_after_callback, 3) do
      metadata = Utils.fetch_metadata(api_parameters)

      with %ExUssd{error: error} = current_menu <-
             apply(resolve, :ussd_after_callback, [
               %{menu | resolve: nil, error: nil},
               api_parameters,
               metadata
             ]) do
        cond do
          is_bitstring(error) ->
            build_response_menu(:halt, current_menu, menu, api_parameters)

          is_bitstring(original_error) ->
            build_response_menu(
              :halt,
              %{current_menu | error: original_error},
              menu,
              api_parameters
            )

          true ->
            build_response_menu(:ok, current_menu, menu, api_parameters)
        end
      end
    end
  end

  def execute_after_callback(_menu, _api_parameters), do: nil

  defp build_response_menu(:halt, current_menu, %{resolve: resolve}, _api_parameters),
    do: {:halt, %{current_menu | resolve: resolve}}

  defp build_response_menu(:ok, current_menu, menu, %{session_id: session} = api_parameters) do
    %{route: route} = ExUssd.Route.get_route(api_parameters)
    ExUssd.Registry.add_route(session, route)
    {:ok, %{current_menu | parent: fn -> menu end}}
  end
end
