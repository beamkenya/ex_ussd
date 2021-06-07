defmodule ExUssd.Utils do
  alias ExUssd.{Error, Op, Registry}

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
    menu = apply(handler, :init, [menu, api_parameters])

    validation_handler =
      get_in(menu, [Access.key(:validation_menu), Access.elem(0), Access.key(:handler)])

    if validation_handler == handler,
      do: menu,
      else:
        apply(validation_handler, :init, [menu, api_parameters])
        |> Map.put(
          :validation_menu,
          {Op.new(%{name: "", handler: handler, data: menu.data}), true}
        )
  end

  def invoke_init(%ExUssd{handler: handler} = menu, api_parameters) do
    apply(handler, :init, [menu, api_parameters])
  end

  def invoke_before_route(%ExUssd{handler: handler} = menu, api_parameters) do
    if function_exported?(handler, :before_route, 2),
      do: apply(handler, :before_route, [menu, api_parameters]),
      else: nil
  end

  def invoke_after_route(
        %ExUssd{handler: handler} = menu,
        {:ok, %{api_parameters: api_parameters} = payload}
      ) do
    if function_exported?(handler, :after_route, 1) do
      apply(handler, :after_route, [
        {:ok, Map.put(payload, :metadata, get_metadata(menu, api_parameters))}
      ])

      {:ok, menu}
    else
      {:ok, menu}
    end
  end

  def invoke_after_route(%ExUssd{handler: handler, data: data} = menu, {:error, api_parameters}) do
    if function_exported?(handler, :after_route, 1) do
      current_menu =
        validate(
          apply(handler, :after_route, [
            {:error, %ExUssd{name: "", handler: handler, data: data},
             %{api_parameters: api_parameters, metadata: get_metadata(menu, api_parameters)}}
          ]),
          handler
        )

      if current_menu == %ExUssd{name: "", handler: handler, data: data},
        do: Map.merge(menu, %{error: {Map.get(menu, :default_error), true}}),
        else: current_menu
    else
      menu
    end
  end

  def get_metadata(%ExUssd{name: name}, %{
        service_code: service_code,
        session_id: session_id,
        text: text
      }) do
    route =
      Registry.get(session_id)
      |> Enum.reverse()
      |> get_in([Access.all(), :value])
      |> tl()
      |> Enum.join("*")

    service_code = String.replace(service_code, "#", "")
    route = if route == "", do: service_code <> "#", else: service_code <> "*" <> route <> "#"

    %{name: name, invoked_at: DateTime.utc_now(), route: route, text: text}
  end

  defp validate(%ExUssd{} = menu, _), do: menu

  defp validate(v, handler),
    do:
      raise(Error,
        message: "'after_route/2' on #{inspect(handler)} must return menu found #{inspect(v)}"
      )
end
