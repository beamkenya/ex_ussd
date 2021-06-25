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
    set_validation_handler(current_menu, api_parameters)
  end

  def invoke_init(%ExUssd{} = menu, api_parameters),
    do: apply_effect(menu, api_parameters)

  defp set_validation_handler(%ExUssd{validation_menu: {validation_menu, _}} = menu, _)
       when is_nil(validation_menu) do
    menu
  end

  defp set_validation_handler(%ExUssd{data: data, handler: handler} = menu, _) do
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

  def invoke_after_route(%ExUssd{handler: handler} = menu, payload) do
    payload = Tuple.to_list(payload)
    route = Enum.at(payload, 2)
    api_parameters = Enum.at(payload, 1)

    if function_exported?(handler, :after_route, 1) do
      args = %{
        state: :error,
        menu: menu,
        payload: %{
          api_parameters: api_parameters,
          metadata: get_metadata(menu, Map.put(api_parameters, :route, route))
        }
      }

      current_menu = validate(menu, apply(handler, :after_route, [args]))
      handle_after_route(menu, current_menu, api_parameters)
    else
      {:ok, menu}
    end
  end

  defp handle_after_route(_, %ExUssd{validation_menu: {validation_menu, _}} = current_menu, _)
       when is_nil(validation_menu) do
    {:error, current_menu}
  end

  defp handle_after_route(
         %ExUssd{handler: handler},
         %ExUssd{validation_menu: {%ExUssd{handler: validation_handler}, _}} = current_menu,
         _
       )
       when handler == validation_handler do
    {:error, current_menu}
  end

  defp handle_after_route(
         _,
         %ExUssd{validation_menu: {%ExUssd{handler: validation_handler}, _}} = current_menu,
         api_parameters
       ) do
    menu = Op.new(%{name: "", handler: validation_handler, data: current_menu.data})
    menu = Map.put(menu, :parent, fn -> %{current_menu | error: {nil, true}} end)
    {:ok, apply_effect(menu, api_parameters)}
  end

  defp apply_effect(%ExUssd{handler: handler} = menu, api_parameters) do
    cond do
      function_exported?(handler, :init, 2) ->
        apply(handler, :init, [menu, api_parameters])

      function_exported?(handler, :init, 3) ->
        metadata = get_metadata(menu, api_parameters)
        apply(handler, :init, [menu, api_parameters, metadata])
    end
  end

  defp get_metadata(
         _,
         %{service_code: service_code, session_id: session_id, text: text} = payload
       ) do
    route = Map.get(payload, :route)

    route = if not is_nil(route), do: [route], else: []
    routes = Registry.get(session_id) |> Enum.reverse()
    routes = routes ++ route

    [_ | route] = get_in(routes, [Access.all(), :value])
    route = Enum.join(route, "*")

    [%{attempt: attempt} | _] = Enum.reverse(routes)

    service_code = String.replace(service_code, "#", "")
    route = if route == "", do: service_code <> "#", else: service_code <> "*" <> route <> "#"
    invoked_at = DateTime.truncate(DateTime.utc_now(), :second)
    %{attempts: attempt, invoked_at: invoked_at, route: route, text: text}
  end

  defp validate(_, %ExUssd{} = menu), do: menu

  defp validate(menu, _), do: menu
end
