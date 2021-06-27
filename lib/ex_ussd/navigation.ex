defmodule ExUssd.Navigation do
  alias ExUssd.{Op, Registry, Utils}

  @default_value 436_739_010_658_356_127_157_159_114_145
  def navigate(
        %ExUssd{} = menu,
        api_parameters,
        route
      ) do
    {menus, _} = menu.menu_list
    {validation_menu, _} = menu.validation_menu
    execute_navigation(menu, Enum.reverse(menus), validation_menu, api_parameters, route)
  end

  defp execute_navigation(
         %ExUssd{orientation: :horizontal} = menu,
         _menus,
         _validation_menu,
         %{session_id: session_id},
         route
       ) do
    depth = to_int(Integer.parse(route[:value]), menu, route[:value])

    case depth do
      128_977_754_852_657_127_041_634_246_588 ->
        %{depth: depth} = Registry.previous(session_id) |> List.first()

        {_, menu} = Registry.get_current(session_id)

        {_, current_menu} =
          case depth do
            1 ->
              Registry.set_attempt(session_id, 0)
              {:ok, menu.parent.()}

            _ ->
              Registry.increase_attempt(session_id)
              {:ok, menu}
          end

        case current_menu.parent do
          nil ->
            {:ok,
             Map.merge(current_menu, %{
               parent: fn -> %{current_menu | error: {nil, true}} end
             })}

          _ ->
            {:ok, current_menu}
        end

      605_356_150_351_840_375_921_999_017_933 ->
        Registry.next(session_id)
        Registry.increase_attempt(session_id)
        Registry.get_current(session_id)

      705_897_792_423_629_962_208_442_626_284 ->
        Registry.set(session_id, %{depth: 1, value: "555"})
        Registry.get_home(session_id)

      436_739_010_658_356_127_157_159_114_145 ->
        {:ok, menu}

      depth ->
        Registry.depth(session_id, depth)
        Registry.increase_attempt(session_id)
        {:ok, menu}
    end
  end

  defp execute_navigation(
         %ExUssd{orientation: :vertical} = menu,
         menus,
         validation_menu,
         %{session_id: session_id} = api_parameters,
         route
       ) do
    depth = to_int(Integer.parse(route[:value]), menu, route[:value])

    case depth do
      128_977_754_852_657_127_041_634_246_588 ->
        %{depth: depth} = Registry.previous(session_id) |> List.first()
        {_, menu} = Registry.get_current(session_id)

        {_, current_menu} =
          case depth do
            1 ->
              Registry.set_attempt(session_id, 0)
              {:ok, menu.parent.()}

            _ ->
              Registry.increase_attempt(session_id)
              {:ok, menu}
          end

        %{previous: {%{name: name}, _}} = current_menu

        Utils.invoke_after_route(
          current_menu,
          {:ok, %{api_parameters: api_parameters, action: name}}
        )

        case current_menu.parent do
          nil ->
            {:ok,
             Map.merge(current_menu, %{
               parent: fn -> %{current_menu | error: {nil, true}} end
             })}

          _ ->
            {:ok, current_menu}
        end

      605_356_150_351_840_375_921_999_017_933 ->
        %{next: {%{name: name}, _}} = menu
        Utils.invoke_after_route(menu, {:ok, %{api_parameters: api_parameters, action: name}})
        Registry.next(session_id)
        Registry.increase_attempt(session_id)
        Registry.get_current(session_id)

      705_897_792_423_629_962_208_442_626_284 ->
        Utils.invoke_after_route(menu, {:ok, %{api_parameters: api_parameters, action: "HOME"}})
        Registry.set(session_id, %{depth: 1, value: "555"})
        Registry.set_attempt(session_id, 0)
        Registry.get_home(session_id)

      depth ->
        session = Registry.get(session_id)
        next_menu(depth, menus, validation_menu, api_parameters, menu, route, session)
    end
  end

  defp next_menu(555, _, _, %{session_id: session_id} = api_parameters, menu, route, _) do
    Registry.set(session_id, route)
    menu = Utils.invoke_init(menu, api_parameters)
    {validation_menu, _} = menu.validation_menu

    menu =
      if is_nil(validation_menu),
        do: menu,
        else: Map.merge(menu, %{validation_menu: {nil, true}, validation_data: validation_menu})

    {:ok, menu}
  end

  defp next_menu(_depth, [], validation_menu, api_parameters, menu, route, _) do
    get_validation_menu(validation_menu, api_parameters, menu, route)
  end

  defp next_menu(
         depth,
         menus,
         nil,
         %{session_id: session_id} = api_parameters,
         menu,
         route,
         session
       )
       when length(session) == 1 do
    if is_nil(Map.get(menu, :validation_data)) do
      next_menu(depth, menus, nil, api_parameters, menu, route, nil)
    else
      case get_validation_menu(menu.validation_data, api_parameters, menu, route) do
        {:error, menu} ->
          menu
          |> Utils.invoke_after_route({:error, api_parameters})
          |> case do
            {:ok, _} = current_menu ->
              Registry.add(session_id, route)
              current_menu

            current_menu ->
              current_menu
          end

        menu ->
          menu
      end
    end
  end

  defp next_menu(depth, menus, nil, %{session_id: session_id} = api_parameters, menu, route, _)
       when is_integer(depth) do
    case Enum.at(menus, depth - 1) do
      nil ->
        Registry.increase_attempt(session_id)

        Map.merge(menu, %{error: Map.get(menu, :default_error)})
        |> Utils.invoke_after_route({:error, api_parameters})
        |> case do
          {:ok, _} = current_menu ->
            Registry.add(session_id, route)
            current_menu

          current_menu ->
            current_menu
        end

      child_menu ->
        Registry.add(session_id, route)
        current_menu = Utils.invoke_init(child_menu, api_parameters)
        current_menu = Map.put(current_menu, :parent, fn -> %{menu | error: {nil, true}} end)
        {:ok, menu} |> after_route(api_parameters, route)
        {:ok, current_menu}
    end
  end

  defp next_menu(
         depth,
         menus,
         validation_menu,
         %{session_id: session_id} = api_parameters,
         menu,
         route,
         _
       ) do
    case get_validation_menu(validation_menu, api_parameters, menu, route) do
      {:error, current_menu} ->
        if Enum.at(menus, depth - 1) == nil do
          Registry.increase_attempt(session_id)
          {:error, current_menu} |> after_route(api_parameters, route)
        else
          next_menu(depth, menus, nil, api_parameters, menu, route, nil)
        end

      current_menu ->
        current_menu |> after_route(api_parameters, route)
    end
  end

  defp get_validation_menu(nil, api_parameters, menu, route) do
    get_validation_menu(menu, api_parameters, menu, route)
  end

  defp get_validation_menu(
         %ExUssd{handler: handler} = validation_menu,
         %{session_id: session_id} = api_parameters,
         menu,
         route
       ) do
    case Utils.invoke_before_route(validation_menu, Map.put(api_parameters, :text, route.value)) do
      nil ->
        Registry.increase_attempt(session_id)

        Map.merge(menu, %{error: Map.get(menu, :default_error)})
        |> Utils.invoke_after_route({:error, api_parameters, route})
        |> case do
          {:ok, _} = current_menu ->
            Registry.add(session_id, route)
            current_menu

          current_menu ->
            current_menu
        end

      %ExUssd{
        error: {error, _},
        validation_menu: {current_validation_menu, _}
      } = current_menu ->
        cond do
          is_nil(error) and not is_nil(current_validation_menu) and
            current_validation_menu.handler == handler and current_menu != validation_menu ->
            Registry.increase_attempt(session_id)
            Registry.add(session_id, route)

            {:ok, current_menu} |> after_route(api_parameters, route)

            {:ok,
             Map.merge(current_menu, %{
               parent: fn -> %{menu | error: {nil, true}} end,
               validation_menu: {nil, true}
             })}

          is_nil(error) and not is_nil(current_validation_menu) and
              current_validation_menu.handler != handler ->
            Registry.increase_attempt(session_id)
            Registry.add(session_id, route)

            {:ok, current_menu} |> after_route(api_parameters, route)

            current_menu = Utils.invoke_init(current_validation_menu, api_parameters)

            validation_menu =
              if is_nil(Utils.can_invoke_before_route?(current_menu.handler)) do
                nil
              else
                Op.new(%{name: "", handler: current_menu.handler, data: current_menu.data})
              end

            {:ok,
             Map.merge(current_menu, %{
               parent: fn -> %{menu | error: {nil, true}} end,
               validation_menu: {validation_menu, false}
             })}

          true ->
            parent = if is_nil(menu.parent), do: menu, else: menu.parent.()
            {menus, _} = menu.menu_list

            error =
              if menus == [] do
                if is_nil(error), do: Map.get(menu, :default_error), else: {error, true}
              else
                Map.get(menu, :default_error)
              end

            {:error,
             Map.merge(menu, %{
               error: error,
               parent: fn -> %{parent | error: {nil, true}} end
             })}
        end
    end
  end

  defp after_route({:ok, current_menu}, api_parameters, _) do
    if function_exported?(current_menu.handler, :after_route, 1) do
      Utils.invoke_after_route(current_menu, {:ok, %{api_parameters: api_parameters}})
    end

    {:ok, current_menu}
  end

  defp after_route({:error, current_menu}, api_parameters, route) do
    if function_exported?(current_menu.handler, :after_route, 1) do
      case Utils.invoke_after_route(current_menu, {:error, api_parameters}) do
        {:error, menu} ->
          {:error, menu}

        {:ok, validation_menu} ->
          {current_validation_menu, _} = validation_menu.validation_menu

          case current_validation_menu do
            nil -> {:ok, validation_menu}
            _ -> get_validation_menu(validation_menu, api_parameters, current_menu, route)
          end
      end
    else
      {:error, Map.merge(current_menu, %{error: Map.get(current_menu, :default_error)})}
    end
  end

  defp to_int({0, _}, menu, input_value), do: to_int({@default_value, ""}, menu, input_value)

  defp to_int({value, ""}, menu, input_value) do
    %{
      next: {%{next: next}, _},
      previous: {%{previous: previous}, _}
    } = menu

    case input_value do
      v when v == next ->
        605_356_150_351_840_375_921_999_017_933

      v when v == previous ->
        128_977_754_852_657_127_041_634_246_588

      _ ->
        value
    end
  end

  defp to_int(:error, _menu, _input_value), do: @default_value

  defp to_int({_value, _}, _menu, _input_value), do: @default_value
end
