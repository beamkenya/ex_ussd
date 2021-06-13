defmodule ExUssd.Utils do
  alias ExUssd.{Op, Registry}

  def truncate(text, options \\ []) do
    len = options[:length] || 145
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

  def invoke_init(
        %ExUssd{handler: handler, validation_menu: {validation_menu, _}} = menu,
        api_parameters
      )
      when not is_nil(validation_menu) do
    menu = apply_effect(menu, api_parameters)

    %ExUssd{handler: validation_handler} =
      validation_menu = get_in(menu, [Access.key(:validation_menu), Access.elem(0)])

    if validation_handler == handler do
      menu
    else
      current_menu = apply_effect(validation_menu, api_parameters)
      new_menu = Op.new(%{name: "", handler: handler, data: current_menu.data})
      Map.put(current_menu, :validation_menu, {new_menu, true})
    end
  end

  def invoke_init(%ExUssd{} = menu, api_parameters),
    do: apply_effect(menu, api_parameters)

  def invoke_before_route(%ExUssd{handler: handler} = menu, api_parameters) do
    cond do
      function_exported?(handler, :before_route, 2) ->
        apply(handler, :before_route, [menu, api_parameters])

      function_exported?(handler, :callback, 2) ->
        msg = "deprecated handler @callback, rename to @before_route callback"
        IO.warn(msg, Macro.Env.stacktrace(__ENV__))
        apply(handler, :callback, [menu, api_parameters])

      function_exported?(handler, :before_route, 3) ->
        apply(handler, :before_route, [menu, api_parameters, get_metadata(menu, api_parameters)])

      true ->
        nil
    end
  end

  def invoke_after_route(
        %ExUssd{handler: handler} = menu,
        {:ok, %{api_parameters: api_parameters} = payload}
      ) do
    if function_exported?(handler, :after_route, 1) do
      apply(handler, :after_route, [
        %{state: :ok, payload: Map.put(payload, :metadata, get_metadata(menu, api_parameters))}
      ])
    end
  end

  def invoke_after_route(%ExUssd{handler: handler} = menu, {:error, api_parameters}) do
    if function_exported?(handler, :after_route, 1) do
      msg = "deprecated handler @navigation_response, rename to @after_route callback"
      IO.warn(msg, Macro.Env.stacktrace(__ENV__))

      current_menu = apply_effect(handler, api_parameters, menu)

      validation_handler =
        get_in(current_menu, [Access.key(:validation_menu), Access.elem(0), Access.key(:handler)])

      apply_effect(handler, validation_handler, current_menu, api_parameters)
    else
      {:ok, menu}
    end
  end

  def invoke_after_route(%ExUssd{handler: handler} = menu, {:ok, payload}) do
    api_parameters = Map.get(payload, :api_parameters, payload)

    if function_exported?(handler, :navigation_response, 1) do
      msg = "deprecated handler @navigation_response, rename to @after_route callback"
      IO.warn(msg, Macro.Env.stacktrace(__ENV__))

      args = %{
        state: :ok,
        payload: Map.put(payload, :metadata, get_metadata(menu, api_parameters))
      }

      apply(handler, :navigation_response, [args])
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

  defp apply_effect(handler, api_parameters, menu) when is_map(api_parameters) do
    args = %{
      state: :error,
      menu: menu,
      payload: %{
        api_parameters: api_parameters,
        metadata: get_metadata(menu, api_parameters)
      }
    }

    response = apply(handler, :after_route, [args])
    validate(menu, response, handler)
  end

  defp apply_effect(handler, validation_handler, menu, api_parameters)
       when validation_handler == handler do
    {:error, menu}
  end

  defp apply_effect(handler, validation_handler, menu, api_parameters) do
    new_menu = Op.new(%{name: "", handler: validation_handler, data: menu.data})
    new_menu = Map.put(new_menu, :parent, fn -> %{menu | error: {nil, true}} end)
    menu = apply(validation_handler, :init, [new_menu, api_parameters])
    {:ok, menu}
  end

  defp get_metadata(_, %{service_code: service_code, session_id: session_id, text: text}) do
    [_ | routes] = Registry.get(session_id) |> Enum.reverse() |> get_in([Access.all(), :value])

    routes = Enum.join(routes, "*")

    service_code = String.replace(service_code, "#", "")
    route = if route == "", do: service_code <> "#", else: service_code <> "*" <> route <> "#"
    invoked_at = DateTime.truncate(DateTime.utc_now(), :second)
    %{invoked_at: invoked_at, route: route, text: text}
  end

  defp validate(_, %ExUssd{} = menu, _), do: menu

  defp validate(menu, _, _), do: menu
end
