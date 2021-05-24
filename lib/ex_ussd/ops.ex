defmodule ExUssd.Ops do
  alias ExUssd.Navigation

  def circle([%{depth: 1, value: "555"}] = route, %ExUssd{} = menu, api_parameters) do
    head = List.first(route)
    navigate(head, menu, api_parameters)
  end

  def circle([head | tail], %ExUssd{} = menu, api_parameters) do
    navigate(head, menu, api_parameters)
    |> case do
      {:ok, current_menu} -> circle(tail, current_menu, api_parameters)
      {:error, current_menu} -> {:ok, current_menu}
    end
  end

  def circle([], %ExUssd{} = menu, _api_parameters) do
    {:ok, menu}
  end

  def circle(route, %ExUssd{} = _current_menu, api_parameters, %ExUssd{} = menu)
      when is_list(route) do
    circle(Enum.reverse(route), menu, api_parameters)
  end

  def circle(route, %ExUssd{} = current_menu, api_parameters, %ExUssd{} = _menu)
      when is_map(route) do
    navigate(route, current_menu, api_parameters)
  end

  def navigate(%{} = route, %ExUssd{} = menu, api_parameters) do
    Navigation.navigate(menu, api_parameters, route)
  end
end
