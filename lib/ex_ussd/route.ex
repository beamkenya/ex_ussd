defmodule ExUssd.Route do
  @doc """
  Process text and service_code infomation to produce routes
  ## Parameters
  * `%{text: text, service_code: service_code}`
  ## Examples
      iex> ExUssd.Route.get_route(%{text: "*544#", service_code: "*544#"})
      [%{depth: 1, value: "555"}]
      iex> ExUssd.Route.get_route(%{text: "*544*2*3#", service_code: "*544#"})
      [%{depth: 1, value: "3"}, %{depth: 1, value: "2"}, %{depth: 1, value: "555"}]
      iex> ExUssd.Route.get_route(%{text: "2", service_code: "*544#"})
      %{depth: 1, value: "2"}
  """

  alias ExUssd.Registry

  def get_route(%{text: text, service_code: service_code, session_id: session_id}) do
    find_route_for_service_code(text, service_code, session_id)
  end

  # Private Funcs
  defp clean(text), do: text |> String.replace("#", "") |> String.split("*")

  defp find_route_for_service_code(text, service_code, session_id) do
    text_value = text |> String.replace("#", "")
    service_code_value = service_code |> String.replace("#", "")

    cond do
      text_value == service_code_value -> [%{depth: 1, value: "555"}]
      text_value =~ service_code_value -> take_range(clean(text), clean(service_code))
      true -> get_route(clean(text), clean(service_code), session_id)
    end
  end

  defp get_route([""], _service_code, _session_id), do: [%{depth: 1, value: "555"}]

  defp get_route([first | _rest = []], _service_code, session_id) do
    case Registry.lookup(session_id) do
      {:error, :not_found} -> [%{depth: 1, value: first}, %{depth: 1, value: "555"}]
      _ -> %{depth: 1, value: first}
    end
  end

  defp get_route([head | tail] = route, _service_code, session_id) do
    case Registry.lookup(session_id) do
      {:error, :not_found} ->
        if head == "", do: to_map(tail), else: to_map(route)

      {:ok, _pid} ->
        %{depth: 1, value: List.last(route)}
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
