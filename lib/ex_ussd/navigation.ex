defmodule ExUssd.Navigation do
  @moduledoc false
  alias ExUssd.{Executer, Registry, Route, Utils}

  def navigate(routes, menu, %{session_id: session_id} = api_parameters) do
    fun = fn
      %Route{mode: :parallel, route: route}, api_parameters, session_id, menu ->
        Registry.start(session_id)
        execute_navigation(Enum.reverse(route), api_parameters, menu)

      %Route{mode: :serial, route: route}, api_parameters, session_id, _ ->
        execute_navigation(route, api_parameters, Registry.fetch_current(session_id))
    end

    with {:ok, menu} <- apply(fun, [routes, api_parameters, session_id, menu]),
         do: Registry.set_current(session_id, menu)
  end

  defp execute_navigation(route, api_parameters, menu) when is_list(route) do
    fun = fn
      [], _api_parameters, menu ->
        {:ok, menu}

      [%{depth: _, text: "555"}] = route, api_parameters, menu ->
        execute_navigation(List.first(route), api_parameters, menu)

      [head | tail], api_parameters, menu ->
        case execute_navigation(head, api_parameters, menu) do
          {:ok, current_menu} -> execute_navigation(tail, api_parameters, current_menu)
          {:skip, current_menu} -> {:ok, current_menu}
        end
    end

    apply(fun, [route, api_parameters, menu])
  end

  defp execute_navigation(
         %{depth: _, text: "555"} = route,
         %{session_id: session} = api_parameters,
         %ExUssd{orientation: :vertical} = menu
       )
       when is_map(route) do
    Registry.add_route(session, route)

    {_, home} =
      menu
      |> Executer.execute_navigate(api_parameters)
      |> Executer.execute(api_parameters)

    {:ok, Registry.set_home(session, %{home | parent: fn -> home end})}
  end

  defp execute_navigation(
         route,
         %{session_id: session} = api_parameters,
         %ExUssd{orientation: :vertical} = menu
       )
       when is_map(route) do
    case Utils.to_int(Integer.parse(route[:text]), menu, route[:text]) do
      705_897_792_423_629_962_208_442_626_284 ->
        Registry.set(session, [%{depth: 1, text: "555"}])
        {:ok, Registry.fetch_home(session)}

      605_356_150_351_840_375_921_999_017_933 ->
        Registry.next_route(session)
        {:ok, menu}

      128_977_754_852_657_127_041_634_246_588 ->
        %{depth: depth} = Registry.route_back(session)

        if depth == 1 do
          {:ok, menu.parent.()}
        else
          {:ok, menu}
        end

      position ->
        get_menu(position, route, menu, api_parameters)
    end
  end

  defp get_menu(_pos, _route, %ExUssd{menu_list: []} = menu, api_parameters) do
    with nil <- Executer.execute_callback(menu, api_parameters, %{metadata: true}) do
      {:skip, menu}
    end
  end

  defp get_menu(
         position,
         route,
         %ExUssd{menu_list: menu_list} = menu,
         %{session_id: session} = api_parameters
       ) do
    menu = Executer.execute_navigate(menu, api_parameters)

    with nil <- Executer.execute_callback(menu, api_parameters, %{metadata: true}) do
      case Enum.at(Enum.reverse(menu_list), position - 1) do
        # invoke the child init callback
        %ExUssd{} = menu ->
          Registry.add_route(session, route)

          {_, current_menu} = Executer.execute(menu, api_parameters)

          {:ok, %{current_menu | parent: fn -> menu end}}

        nil ->
          {:skip, menu}
      end
    end
  end
end
