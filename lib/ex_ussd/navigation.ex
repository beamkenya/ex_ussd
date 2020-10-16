alias ExUssd.Utils
alias ExUssd.State.Registry

defmodule ExUssd.Navigation do

  def navigate(session_id, [_hd | _tl] = routes, menu, api_parameters) do
    Registry.add(session_id, routes)
    results = loop(routes, menu, api_parameters)
    Registry.add_current_menu(session_id, results)
  end

  def navigate(session_id, %{} = route, _menu, api_parameters) do
    parent_menu = Registry.get_current_menu(session_id)
    handle_current_menu(session_id, route, parent_menu, api_parameters)
  end
  def loop([_head | tail] = routes, menu, api_parameters) when is_list(routes) and length(routes) == 1 do
    loop(tail, menu, api_parameters)
  end

  def loop(routes, menu, _api_parameters) when is_list(routes) and length(routes) == 0 do
    menu
  end

  def loop(routes, menu, api_parameters) when is_list(routes) and length(routes) > 1 do
    [head | tail] = Enum.reverse(routes) |> tl
    response = get_next_menu(menu, head, api_parameters)
    response |> Map.put(:parent, menu)
    loop(tail, response, api_parameters)
  end

  def get_next_menu(parent_menu, state, api_parameters) do
    %{menu_list: menu_list} = parent_menu
    depth = to_int(Integer.parse(state[:value]), parent_menu)

    child_menu = case Enum.at(menu_list, depth - 1) do
      nil -> Enum.at(menu_list, 0)
      _ -> Enum.at(menu_list, depth - 1)
    end
    Utils.call_menu_callback(child_menu, api_parameters)
  end

  def handle_current_menu(session_id, state, parent_menu, api_parameters) do
    %{menu_list: menu_list} = parent_menu
    depth = to_int(Integer.parse(state[:value]), parent_menu)
    case Enum.at(menu_list, depth - 1) do
      nil ->
        case depth do
          128977754852657127041634246588 ->
            Registry.previous(session_id)
            parent_menu.parent
          605356150351840375921999017933 ->
            Registry.next(session_id)
            parent_menu
          _->
            %{handle: handle} = parent_menu
            case handle do
              true ->
                can_handle?(parent_menu, api_parameters, state, session_id)
              false ->
                parent_menu |> Map.put(:error, parent_menu.default_error_message)
              end
          end
      _ ->
        Registry.add(session_id, state)
        child_menu = Enum.at(menu_list, depth - 1)
        Utils.call_menu_callback(child_menu, api_parameters)
    end
  end

  def can_handle?(parent_menu, api_parameters, state, session_id) do
    current_menu = Utils.call_menu_callback(parent_menu, api_parameters, true)
    %{success: success} = current_menu
    case success do
      false ->
        current_menu
      _->
        Registry.add(session_id, state)
        %{menu_list: current_menu_list} = current_menu
        next_parent =  Enum.at(current_menu_list, 0)
        Utils.call_menu_callback(next_parent, api_parameters)
    end
  end
  def to_int({value, ""}, menu) do
    %{next: next, previous: previous, menu_list: menu_list } = menu
    text = Integer.to_string(value)
    case text do
      v when v == next -> 605356150351840375921999017933
      v when v == previous -> 128977754852657127041634246588
      _ ->
        case length(menu_list) do
          1 -> 437325457672214320980
          _ -> value
        end
    end
  end

  def to_int(:error, _menu), do: 999

  def to_int({_value, _} , _menu), do: 999
end
