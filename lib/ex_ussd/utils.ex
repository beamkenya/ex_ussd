defmodule ExUssd.Utils do
  alias ExUssd.Op

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

  def invoke_after_route(%ExUssd{handler: handler} = menu, {:ok, payload}) do
    if function_exported?(handler, :after_route, 1) do
      apply(handler, :after_route, [{:ok, payload}])
      {:ok, menu}
    else
      {:ok, menu}
    end
  end

  def invoke_after_route(%ExUssd{handler: handler} = menu, {:error, api_parameters}) do
    if function_exported?(handler, :after_route, 1),
      do: apply(handler, :after_route, [{:error, menu, api_parameters}]),
      else: nil
  end
end
