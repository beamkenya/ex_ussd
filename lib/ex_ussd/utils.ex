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
        len_with_omi = len - String.length(omi)

        stop =
          if options[:separator] do
            rindex(text, options[:separator], len_with_omi) || len_with_omi
          else
            len_with_omi
          end

        "#{String.slice(text, 0, stop)}#{omi}"
    end
  end

  defp rindex(text, str, _offset) do
    revesed = text |> String.reverse()
    matchword = String.reverse(str)

    case :binary.match(revesed, matchword) do
      {at, strlen} ->
        String.length(text) - at - strlen

      :nomatch ->
        nil
    end
  end

  def invoke_init(
        %ExUssd{handler: handler, validation_menu: {validation_menu, _}} = menu,
        api_parameters
      )
      when not is_nil(validation_menu) do
    menu = invoke_init_with_arity(menu, api_parameters)

    %ExUssd{handler: validation_handler} =
      validation_menu = get_in(menu, [Access.key(:validation_menu), Access.elem(0)])

    if validation_handler == handler do
      menu
    else
      menu = invoke_init_with_arity(validation_menu, api_parameters)

      Map.put(
        menu,
        :validation_menu,
        {Op.new(%{name: "", handler: handler, data: menu.data}), true}
      )
    end
  end

  def invoke_init(%ExUssd{} = menu, api_parameters),
    do: invoke_init_with_arity(menu, api_parameters)

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
      current_menu =
        validate(
          menu,
          apply(handler, :after_route, [
            %{
              state: :error,
              menu: menu,
              payload: %{
                api_parameters: api_parameters,
                metadata: get_metadata(menu, api_parameters)
              }
            }
          ]),
          handler
        )

      validation_handler =
        get_in(current_menu, [Access.key(:validation_menu), Access.elem(0), Access.key(:handler)])

      if validation_handler == handler do
        {:error, current_menu}
      else
        {:ok,
         apply(validation_handler, :init, [
           Map.merge(
             Op.new(%{name: "", handler: validation_handler, data: current_menu.data}),
             %{
               parent: fn -> %{current_menu | error: {nil, true}} end
             }
           ),
           api_parameters
         ])}
      end
    else
      {:ok, menu}
    end
  end

  def invoke_after_route(%ExUssd{handler: handler} = menu, {state, payload}) do
    api_parameters = Map.get(payload, :api_parameters, payload)

    if function_exported?(handler, :navigation_response, 1) do
      msg = "deprecated handler @navigation_response, rename to @after_route callback"
      IO.warn(msg, Macro.Env.stacktrace(__ENV__))

      apply(handler, :navigation_response, [
        %{state: state, payload: Map.put(payload, :metadata, get_metadata(menu, api_parameters))}
      ])
    end
  end

  defp get_metadata(_, %{service_code: service_code, session_id: session_id, text: text}) do
    routes = Registry.get(session_id)

    route =
      routes
      |> Enum.reverse()
      |> get_in([Access.all(), :value])
      |> tl()
      |> Enum.join("*")

    service_code = String.replace(service_code, "#", "")
    route = if route == "", do: service_code <> "#", else: service_code <> "*" <> route <> "#"
    invoked_at = DateTime.truncate(DateTime.utc_now(), :second)
    %{invoked_at: invoked_at, route: route, text: text}
  end

  defp invoke_init_with_arity(%ExUssd{handler: handler} = menu, api_parameters) do
    cond do
      function_exported?(handler, :init, 2) ->
        apply(handler, :init, [menu, api_parameters])

      function_exported?(handler, :init, 3) ->
        apply(handler, :init, [menu, api_parameters, get_metadata(menu, api_parameters)])
    end
  end

  defp validate(_, %ExUssd{} = menu, _), do: menu

  defp validate(menu, _, _), do: menu
end
