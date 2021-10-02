defmodule ExUssd.Navigation do
  @moduledoc false

  alias ExUssd.{Executer, Registry, Route, Utils}

  defguard is_menu(value) when is_tuple(value) and is_struct(elem(value, 1), ExUssd)

  @doc """
  Its used to navigate ExUssd menus.
  """
  @spec navigate(ExUssd.Route.t(), ExUssd.t(), map()) :: ExUssd.t()
  def navigate(routes, menu, %{session_id: session_id} = payload) do
    fun = fn
      %Route{mode: :parallel, route: route}, payload, session_id, menu ->
        Registry.start(session_id)
        execute_navigation(Enum.reverse(route), payload, menu)

      %Route{mode: :serial, route: route}, payload, session_id, _ ->
        execute_navigation(route, payload, Registry.fetch_current(session_id))
    end

    with {_, menu} <- apply(fun, [routes, payload, session_id, menu]),
         do: Registry.set_current(session_id, menu)
  end

  @spec execute_navigation(map() | list(), map(), ExUssd.t()) :: {term(), ExUssd.t()}
  defp execute_navigation(route, payload, menu)

  defp execute_navigation(route, payload, menu) when is_list(route) do
    fun = fn
      [], _payload, menu ->
        {:ok, menu}

      [%{depth: _, text: "555"}] = route, payload, menu ->
        execute_navigation(List.first(route), payload, menu)

      [head | tail], payload, menu ->
        case execute_navigation(head, payload, menu) do
          {:ok, current_menu} -> execute_navigation(tail, payload, current_menu)
          {:halt, current_menu} -> {:ok, current_menu}
        end
    end

    apply(fun, [route, payload, menu])
  end

  defp execute_navigation(
         %{depth: _, text: "555"} = route,
         %{session_id: session} = payload,
         %ExUssd{} = menu
       )
       when is_map(route) do
    Registry.add_route(session, route)

    {:ok, home} =
      menu
      |> Executer.execute_navigate(payload)
      |> Executer.execute_init_callback(payload)

    {:ok, Registry.set_home(session, %{home | parent: fn -> home end})}
  end

  defp execute_navigation(
         route,
         %{session_id: session} = payload,
         %ExUssd{orientation: :vertical, parent: parent} = menu
       )
       when is_map(route) do
    payload = %{payload | text: route[:text]}

    case Utils.to_int(Integer.parse(route[:text]), menu, payload, route[:text]) do
      705_897_792_423_629_962_208_442_626_284 ->
        Registry.set(session, [%ExUssd.Route.State{depth: 1, text: "555"}])
        {:ok, Registry.fetch_home(session)}

      605_356_150_351_840_375_921_999_017_933 ->
        Registry.next_route(session)
        {:ok, menu}

      128_977_754_852_657_127_041_634_246_588 ->
        %{depth: depth} = Registry.route_back(session)

        if depth == 1 do
          Registry.reset_attempt(session)
          current = if(is_nil(parent), do: menu, else: parent.())
          {:ok, current}
        else
          {:ok, menu}
        end

      position ->
        position =
          if(String.equivalent?("741_463_257_579_241_461_489_157_167_458", "#{position}"),
            do: 0,
            else: position
          )

        with {_, current_menu} = menu <- get_menu(position, route, menu, payload),
             response when not is_menu(response) <-
               Executer.execute_after_callback(current_menu, payload) do
          menu
        end
    end
  end

  defp execute_navigation(
         route,
         %{session_id: session} = payload,
         %ExUssd{orientation: :horizontal, parent: parent, default_error: default_error} = menu
       )
       when is_map(route) do
    payload = %{payload | text: route[:text]}

    case Utils.to_int(Integer.parse(route[:text]), menu, payload, route[:text]) do
      705_897_792_423_629_962_208_442_626_284 ->
        Registry.set(session, [%ExUssd.Route.State{depth: 1, text: "555"}])
        {:ok, Registry.fetch_home(session)}

      605_356_150_351_840_375_921_999_017_933 ->
        Registry.next_route(session)
        {:ok, menu}

      128_977_754_852_657_127_041_634_246_588 ->
        %{depth: depth} = Registry.route_back(session)

        if depth == 1 do
          Registry.reset_attempt(session)
          current = if(is_nil(parent), do: menu, else: parent.())
          {:ok, current}
        else
          {:ok, menu}
        end

      436_739_010_658_356_127_157_159_114_145 ->
        {:ok, %{menu | error: default_error}}

      position ->
        ExUssd.Registry.set_depth(session, position)
        {:ok, menu}
    end
  end

  defp execute_navigation(_, _, nil),
    do:
      raise(%RuntimeError{message: "menu not found, something went wrong with resolve callback"})

  @spec get_menu(integer(), map(), ExUssd.t(), map()) :: {:ok | :halt, ExUssd.t()}
  defp get_menu(pos, route, menu, payload)

  defp get_menu(
         _pos,
         route,
         %ExUssd{default_error: error, menu_list: []} = menu,
         %{session_id: session} = payload
       ) do
    with response when not is_menu(response) <-
           Executer.execute_callback(menu, payload) do
      Registry.add_attempt(session, route[:text])
      {:halt, %{menu | error: error}}
    end
  end

  defp get_menu(
         position,
         route,
         %ExUssd{default_error: default_error, menu_list: menu_list, is_zero_based: is_zero_based} =
           parent_menu,
         %{session_id: session} = payload
       ) do
    with menu <- Executer.execute_navigate(parent_menu, payload),
         response when not is_menu(response) <-
           Executer.execute_callback(menu, payload) do
      from = if(is_zero_based, do: 0, else: 1)

      case Enum.at(Enum.reverse(menu_list), position - from) do
        # invoke the child init callback
        %ExUssd{} = menu ->
          Registry.add_route(session, route)

          {:ok, current_menu} =
            menu
            |> Executer.execute_navigate(payload)
            |> Executer.execute_init_callback(payload)

          {:ok, %{current_menu | parent: fn -> parent_menu end}}

        nil ->
          Registry.add_attempt(session, route[:text])
          {:halt, %{menu | error: default_error}}
      end
    end
  end
end
