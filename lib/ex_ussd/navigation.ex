defmodule ExUssd.Navigation do
  alias ExUssd.Utils
  alias ExUssd.State.Registry

  @doc """
    Implements the navigation logic

    ## Params
    The function requires two keys as parameters
      `:session_id` - current session id
      `:routes` - ExUssd.Routes routing {list || map}
      `:menu` - current menu struct
      `:api_parameters` - api_parameters data

      Returns %ExUssd.Menu{}.

      ## Example
        iex> defmodule MyHomeHandler do
        ...>   @behaviour ExUssd.Handler
        ...>   def handle_menu(menu, api_parameters, should_handle) do
        ...>     menu |> Map.put(:title, "Welcome")
        ...>   end
        ...> end
        iex> initial_menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)
        iex> menu = ExUssd.Utils.call_menu_callback(initial_menu)
        iex> ExUssd.State.Registry.start("session_01")
        iex> routes = ExUssd.Routes.get_route(%{text: "*544#", service_code: "*544#"})
        iex> ExUssd.Navigation.navigate("session_01",routes, menu, %{text: ""})
        %ExUssd.Menu{
          callback: nil,
          data: nil,
          default_error_message: "Invalid Choice\n",
          display_style: ":",
          error: nil,
          handle: false,
          handler: MyHomeHandler,
          menu_list: [],
          name: "Home",
          next: "98",
          parent: nil,
          previous: "0",
          should_close: false,
          show_navigation: true,
          split: 7,
          success: false,
          title: "Welcome",
          validation_menu: nil
        }
  """

  def navigate(session_id, [_hd | _tl] = routes, menu, api_parameters) do
    Registry.add(session_id, routes)
    results = loop(routes, menu, api_parameters)
    Registry.add_current_menu(session_id, results)
  end

  def navigate(session_id, %{} = route, _menu, api_parameters) do
    parent_menu = Registry.get_current_menu(session_id)

    case parent_menu do
      nil ->
        {:error, "Not Properly started"}

      _ ->
        current_menu = handle_current_menu(session_id, route, parent_menu, api_parameters)

        response =
          case current_menu.parent do
            nil -> %{current_menu | parent: fn -> %{parent_menu | error: nil} end}
            _ -> current_menu
          end

        Registry.add_current_menu(session_id, response)
    end
  end

  defp loop([_head | _tail] = routes, menu, _api_parameters)
       when is_list(routes) and length(routes) == 1 do
    menu
  end

  defp loop(routes, menu, _api_parameters) when is_list(routes) and length(routes) == 0 do
    menu
  end

  defp loop(routes, menu, api_parameters) when is_list(routes) and length(routes) > 1 do
    [head | tail] = Enum.reverse(routes) |> tl
    response = get_next_menu(menu, head, api_parameters)
    response = %{response | parent: fn -> menu end}
    loop(tail, response, api_parameters)
  end

  defp get_next_menu(parent_menu, state, api_parameters) do
    %{menu_list: menu_list} = parent_menu
    depth = to_int(Integer.parse(state[:value]), parent_menu)

    child_menu =
      case Enum.at(menu_list, depth - 1) do
        nil -> parent_menu.validation_menu
        _ -> Enum.at(menu_list, depth - 1)
      end

    Utils.call_menu_callback(child_menu, api_parameters)
  end

  defp handle_current_menu(session_id, state, parent_menu, api_parameters) do
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
            %{validation_menu: validation_menu} = parent_menu

            case validation_menu do
              nil ->
                parent_menu |> Map.put(:error, parent_menu.default_error_message)

              _ ->
                can_handle?(parent_menu, api_parameters, state, session_id, validation_menu)
            end
        end

      _ ->
        Registry.add(session_id, state)
        child_menu = Enum.at(menu_list, depth - 1)
        Utils.call_menu_callback(child_menu, api_parameters)
    end
  end

  defp can_handle?(parent_menu, api_parameters, state, session_id, child_menu) do
    current_menu =
      Utils.call_menu_callback(child_menu, %{api_parameters | text: state.value}, true)

    %{error: error} = current_menu

    case error do
      nil ->
        Registry.add(session_id, state)
        current_menu

      _ ->
        response = %{parent_menu | error: error}
        go_back_menu = case length(Registry.get(session_id)) do
          1 -> parent_menu
          _-> parent_menu.parent.()
        end
        %{response | parent: fn -> %{go_back_menu | error: nil} end}
    end
  end

  defp to_int({value, ""}, menu) do
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

  defp to_int(:error, _menu), do: 999

  defp to_int({_value, _}, _menu), do: 999
end
