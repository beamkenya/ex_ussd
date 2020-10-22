alias ExUssd.Utils
alias ExUssd.State.Registry

defmodule ExUssd.Navigation do
  def navigate(session_id, [_hd | _tl] = routes, menu, api_parameters) do
    Registry.add(session_id, routes)
    results = loop(routes, menu, api_parameters)
    Registry.add_current_menu(session_id, results)
  end

  def navigate(session_id, %{} = route, menu, api_parameters) do
    parent_menu = Registry.get_current_menu(session_id)
    current_menu = handle_current_menu(session_id, route, parent_menu, api_parameters)

    case current_menu do
      nil ->
        ExUssd.Navigation.navigate(session_id, route.routes, menu, api_parameters)

      _ ->
        response =
          case current_menu.parent do
            nil -> %{current_menu | parent: fn -> parent_menu end}
            _ -> current_menu
          end

        Registry.add_current_menu(session_id, response)
    end
  end

  def loop([_head | _tail] = routes, menu, _api_parameters)
      when is_list(routes) and length(routes) == 1 do
    menu
  end

  def loop(routes, menu, _api_parameters) when is_list(routes) and length(routes) == 0 do
    menu
  end

  def loop(routes, menu, api_parameters) when is_list(routes) and length(routes) > 1 do
    [head | tail] = Enum.reverse(routes) |> tl
    response = get_next_menu(menu, head, api_parameters)
    response = %{response | parent: fn -> menu end}
    loop(tail, response, api_parameters)
  end

  def get_next_menu(parent_menu, state, api_parameters) do
    %{menu_list: menu_list} = parent_menu
    depth = to_int(Integer.parse(state[:value]), parent_menu)

    child_menu =
      case Enum.at(menu_list, depth - 1) do
        nil -> parent_menu.validation_menu
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
          128_977_754_852_657_127_041_634_246_588 ->
            route = Registry.previous(session_id) |> hd
            %{depth: depth} = route

            case depth do
              1 -> parent_menu.parent.()
              _ -> parent_menu
            end

          605_356_150_351_840_375_921_999_017_933 ->
            Registry.next(session_id)
            parent_menu

          _ ->
            %{handle: handle} = parent_menu

            case handle do
              true ->
                # Enum.at(menu_list, 0)
                child_menu = parent_menu.validation_menu

                can_handle?(parent_menu, api_parameters, state, session_id, %{
                  child_menu
                  | show_options: false
                })

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

  def can_handle?(parent_menu, api_parameters, state, session_id, child_menu) do
    current_menu =
      Utils.call_menu_callback(child_menu, %{api_parameters | text: state.value}, true)

    %{success: success, error: error} = current_menu

    case success do
      false ->
        response = %{parent_menu | error: error}
        go_back_menu = parent_menu.parent.()
        %{response | parent: fn -> go_back_menu end}

      _ ->
        Registry.add(session_id, state)
        current_menu
    end
  end

  def to_int({value, ""}, menu) do
    %{next: next, previous: previous} = menu
    text = Integer.to_string(value)

    case text do
      v when v == next ->
        605_356_150_351_840_375_921_999_017_933

      v when v == previous ->
        128_977_754_852_657_127_041_634_246_588

      _ ->
        value
    end
  end

  def to_int(:error, _menu), do: 999

  def to_int({_value, _}, _menu), do: 999
end
