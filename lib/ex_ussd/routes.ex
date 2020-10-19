defmodule ExUssd.Routes do
  @doc """
  Process text and service_code infomation to produce routes

  ## Parameters
  * `%{text: text, service_code: service_code}`

  ## Examples
      iex> ExUssd.Routes.get_route(%{text: "*544#", service_code: "*544#"})
      [%{depth: 1, value: "555"}]

      iex> ExUssd.Routes.get_route(%{text: "*544*2*3#", service_code: "*544#"})
      [%{depth: 1, value: "3"}, %{depth: 1, value: "2"}, %{depth: 1, value: "555"}]

      iex> ExUssd.Routes.get_route(%{text: "2", service_code: "*544#"})
      %{depth: 1, value: "2"}
  """

  def get_route(%{text: text, service_code: service_code}) do
    find_route_for_service_code(text, service_code)
  end

  # Private Funcs
  defp clean(text), do: text |> String.replace("#", "") |> String.split("*")

  defp find_route_for_service_code([""], _service_code), do: [%{depth: 1, value: "555"}]

  defp find_route_for_service_code([first | _rest = []], _service_code),
    do: %{depth: 1, value: first}

  defp find_route_for_service_code(text, service_code) do
    text_value = text |> String.replace("#", "")
    service_code_value = service_code |> String.replace("#", "")

    cond do
      text_value == service_code_value -> [%{depth: 1, value: "555"}]
      text_value =~ service_code_value -> take_range(clean(text), clean(service_code))
      true -> find_route_for_service_code(clean(text), clean(service_code))
    end
  end

  defp take_range(positions, shortcode) do
    pos = length(positions)
    stc = length(shortcode)
    diff = pos - stc
    Enum.take(positions, -diff) |> to_map
  end

  defp to_map(list) do
    Enum.reduce(list, [%{depth: 1, value: "555"}], fn item, acc ->
      [Map.put(%{depth: 1}, :value, item) | acc]
    end)
  end
end
