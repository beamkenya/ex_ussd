defmodule ExUssd.Utils do
  alias ExUssd.{Op, Registry}

  def generate_id() do
    min = String.to_integer("1000000000000", 36)
    max = String.to_integer("ZZZZZZZZZZZZZZ", 36)

    max
    |> Kernel.-(min)
    |> :rand.uniform()
    |> Kernel.+(min)
    |> Integer.to_string(36)
  end

  def truncate(text, options \\ []) do
    len = options[:length] || 30
    omi = options[:omission] || "..."

    cond do
      !String.valid?(text) ->
        text

      String.length(text) < len ->
        text

      true ->
        stop = len - String.length(omi)

        "#{String.slice(text, 0, stop)}#{omi}"
    end
  end

  def format_map(api_parameters) do
    Map.new(api_parameters, fn {key, val} ->
      try do
        {String.to_existing_atom(key), val}
      rescue
        _e in ArgumentError ->
          {String.to_atom(key), val}
      end
    end)
  end

  def invoke_init(%ExUssd{validation_menu: {validation_menu, _}} = menu, api_parameters)
      when not is_nil(validation_menu) do
    current_menu = apply_effect(menu, api_parameters)

    invoke_validation_handler(current_menu, api_parameters)
  end

  def invoke_init(%ExUssd{} = menu, api_parameters),
    do: apply_effect(menu, api_parameters)

  defp invoke_validation_handler(%ExUssd{validation_menu: {validation_menu, _}} = menu, _)
       when is_nil(validation_menu) do
    menu
  end

  defp invoke_validation_handler(
         %ExUssd{data: data, handler: handler, validation_menu: {validation_menu, _}},
         api_parameters
       ) do
    menu = apply_effect(validation_menu, api_parameters)
    validation_menu = Op.new(%{name: "", handler: handler, data: data})
    Map.put(menu, :validation_menu, {validation_menu, true})
  end

  def invoke_before_route(%ExUssd{handler: handler} = menu, api_parameters) do
    cond do
      function_exported?(handler, :callback, 2) ->
        apply(handler, :callback, [menu, api_parameters])

      function_exported?(handler, :callback, 3) ->
        apply(handler, :callback, [menu, api_parameters, get_metadata(menu, api_parameters)])

      true ->
        nil
    end
  end

  def can_invoke_before_route?(handler) do
    cond do
      function_exported?(handler, :callback, 2) ->
        :ok

      function_exported?(handler, :callback, 3) ->
        :ok

      true ->
        nil
    end
  end

  def invoke_after_route(%ExUssd{handler: handler} = menu, {:ok, payload}) do
    if function_exported?(handler, :after_route, 1) do
      api_parameters = Map.get(payload, :api_parameters)

      args = %{
        state: :ok,
        payload: Map.put(payload, :metadata, get_metadata(menu, api_parameters))
      }

      apply(handler, :after_route, [args])
    end
  end

  def invoke_after_route(%ExUssd{handler: handler} = menu, {:error, api_parameters}) do
    if function_exported?(handler, :after_route, 1) do
      args = %{
        state: :error,
        menu: menu,
        payload: %{
          api_parameters: api_parameters,
          metadata: get_metadata(menu, api_parameters)
        }
      }

      current_menu = validate(menu, apply(handler, :after_route, [args]), handler)

      validation_handler =
        get_in(current_menu, [Access.key(:validation_menu), Access.elem(0), Access.key(:handler)])

      if validation_handler == handler do
        {:error, current_menu}
      else
        menu = Op.new(%{name: "", handler: validation_handler, data: current_menu.data})
        menu = Map.put(menu, :parent, fn -> %{current_menu | error: {nil, true}} end)
        {:ok, apply_effect(menu, api_parameters)}
      end
    else
      {:ok, menu}
    end
  end

  defp apply_effect(%ExUssd{handler: handler} = menu, api_parameters) do
    cond do
      function_exported?(handler, :init, 2) ->
        apply(handler, :init, [menu, api_parameters])

      function_exported?(handler, :init, 3) ->
        apply(handler, :init, [menu, api_parameters, get_metadata(menu, api_parameters)])
    end
  end

  defp get_metadata(_, %{service_code: service_code, session_id: session_id, text: text}) do
    [_ | routes] = Registry.get(session_id) |> Enum.reverse() |> get_in([Access.all(), :value])
    route = Enum.join(routes, "*")

    service_code = String.replace(service_code, "#", "")
    route = if route == "", do: service_code <> "#", else: service_code <> "*" <> route <> "#"
    invoked_at = DateTime.truncate(DateTime.utc_now(), :second)
    %{invoked_at: invoked_at, route: route, text: text}
  end

  defp validate(_, %ExUssd{} = menu, _), do: menu

  defp validate(menu, _, _), do: menu
end
