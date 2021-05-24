defmodule ExUssd.Navigation do
  alias ExUssd.Registry
  alias ExUssd.Utils

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
            1 -> {:ok, menu.parent.()}
            _ -> {:ok, menu}
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
        Registry.get_current(session_id)

      705_897_792_423_629_962_208_442_626_284 ->
        Registry.set(session_id, %{depth: 1, value: "555"})
        Registry.get_home(session_id)

      436_739_010_658_356_127_157_159_114_145 ->
        {:ok, menu}

      depth ->
        Registry.depth(session_id, depth)
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
            1 -> {:ok, menu.parent.()}
            _ -> {:ok, menu}
          end

        Utils.navigation_response(menu, {:ok, api_parameters})

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
        Utils.navigation_response(menu, {:ok, api_parameters})
        Registry.next(session_id)
        Registry.get_current(session_id)

      705_897_792_423_629_962_208_442_626_284 ->
        Utils.navigation_response(menu, {:ok, api_parameters})
        Registry.set(session_id, %{depth: 1, value: "555"})
        Registry.get_home(session_id)

      depth ->
        next_menu(depth, menus, validation_menu, api_parameters, menu, route)
    end
  end

  defp next_menu(
         555,
         _menus,
         _validation_menu,
         %{session_id: session_id} = api_parameters,
         menu,
         route
       ) do
    Registry.set(session_id, route)
    parent_menu = Utils.invoke_init(menu, api_parameters)

    {:ok,
     Map.merge(parent_menu, %{
       parent: fn -> %{parent_menu | error: {nil, true}} end
     })}
  end

  defp next_menu(_depth, [], validation_menu, api_parameters, menu, route) do
    current_menu = get_validation_menu(validation_menu, api_parameters, menu, route)

    case current_menu do
      {:ok, _} -> Utils.navigation_response(menu, {:ok, api_parameters})
      {:error, _} -> Utils.navigation_response(menu, {:error, api_parameters})
    end

    current_menu
  end

  defp next_menu(depth, menus, nil, %{session_id: session_id} = api_parameters, menu, route)
       when is_integer(depth) do
    case Enum.at(menus, depth - 1) do
      nil ->
        parent = if length(Registry.get(session_id)) == 1, do: menu, else: menu.parent.()
        Utils.navigation_response(menu, {:error, api_parameters})

        {:error,
         Map.merge(menu, %{
           error: {Map.get(menu, :default_error), true},
           parent: fn -> %{parent | error: {nil, true}} end
         })}

      child_menu ->
        Registry.add(session_id, route)
        Utils.navigation_response(menu, {:ok, api_parameters})

        {:ok,
         Map.merge(Utils.invoke_init(child_menu, api_parameters), %{
           parent: fn -> %{menu | error: {nil, true}} end
         })}
    end
  end

  defp next_menu(depth, menus, _validation_menu, api_parameters, menu, %{value: "555"} = route) do
    next_menu(depth, menus, nil, api_parameters, menu, route)
  end

  defp next_menu(depth, menus, validation_menu, api_parameters, menu, route) do
    case get_validation_menu(validation_menu, api_parameters, menu, route) do
      {:error, current_menu} ->
        if Enum.at(menus, depth - 1) == nil do
          Utils.navigation_response(menu, {:error, api_parameters})

          {:error, Map.merge(current_menu, %{error: {Map.get(menu, :default_error), true}})}
        else
          next_menu(depth, menus, nil, api_parameters, menu, route)
        end

      current_menu ->
        current_menu
    end
  end

  defp get_validation_menu(
         validation_menu,
         %{session_id: session_id} = api_parameters,
         menu,
         route
       ) do
    Utils.invoke_callback(validation_menu, Map.put(api_parameters, :text, route.value))
    |> case do
      nil ->
        {:error, Map.merge(menu, %{error: {Map.get(menu, :default_error), true}})}

      %{
        error: {error, _},
        continue: {continue, _},
        title: {title, _},
        validation_menu: {validation_menu, _}
      } = current_menu ->
        cond do
          error == nil and continue == true and title == nil and validation_menu == nil ->
            {:error, Map.merge(menu, %{error: {Map.get(menu, :default_error), true}})}

          error == nil and continue == true and title != nil and validation_menu == nil ->
            Registry.add(session_id, route)

            {:ok,
             Map.merge(current_menu, %{
               parent: fn -> %{menu | error: {nil, true}} end
             })}

          validation_menu != nil ->
            {:ok,
             Map.merge(
               Utils.invoke_init(validation_menu, api_parameters),
               %{
                 parent: fn -> %{menu | error: {nil, true}} end,
                 validation_menu:
                   {%ExUssd{
                      name: "",
                      data: validation_menu.data,
                      handler: validation_menu.handler
                    }, true},
                 show_navigation: {false, true}
               }
             )}

          true ->
            go_back_menu =
              case menu.parent do
                nil -> menu
                _ -> menu.parent.()
              end

            {:error,
             Map.merge(menu, %{
               error: {error, true},
               parent: fn -> %{go_back_menu | error: {nil, true}} end
             })}
        end
    end
  end

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
