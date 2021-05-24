defmodule ExUssd.Display do
  alias ExUssd.{Registry, Utils}

  def new(fields) when is_list(fields),
    do: new(Enum.into(fields, %{}))

  def new(%{
        menu: menu,
        routes: routes,
        api_parameters: api_parameters
      }) do
    builder(menu, routes, api_parameters)
  end

  def new(%{menu: menu, routes: routes}) do
    builder(menu, routes, Map.new())
  end

  defp builder(
         %ExUssd{
           orientation: :horizontal,
           menu_list: {menu_list, _},
           default_error: default_error,
           next: {%{delimiter: next_display_style, next: next, name: next_name}, _},
           previous:
             {%{
                delimiter: previous_display_style,
                previous: previous,
                name: previous_name
              }, _}
         } = menu,
         routes,
         %{session_id: session_id} = api_parameters
       ) do
    %{depth: depth} = List.first(routes)
    total_length = length(menu_list)

    previous_navigation = "#{previous}#{previous_display_style}#{previous_name}"
    next_navigation = "#{next}#{next_display_style}#{next_name}"

    menu =
      cond do
        depth > total_length ->
          Utils.navigation_response(menu, {:error, api_parameters})
          Registry.depth(session_id, total_length + 1)
          menu_string = default_error <> previous_navigation
          %{menu_string: menu_string, should_close: false}

        depth < total_length ->
          Utils.navigation_response(menu, {:ok, api_parameters})
          %{name: name} = Enum.at(menu_list, depth - 1)

          menu_string =
            "#{depth}/#{total_length}\n#{name}\n#{previous_navigation} #{next_navigation}"

          %{menu_string: menu_string, should_close: false}

        depth == total_length ->
          Utils.navigation_response(menu, {:ok, api_parameters})
          %{name: name} = Enum.at(menu_list, depth - 1)
          menu_string = "#{depth}/#{total_length}\n#{name}\n#{previous_navigation}"
          {should_close, _} = menu.should_close
          %{menu_string: menu_string, should_close: should_close}
      end

    {:ok, menu}
  end

  defp builder(
         %ExUssd{
           orientation: :vertical,
           delimiter: {delimiter_style, _},
           error: {error, _},
           menu_list: {menu_list, _},
           next: {%{delimiter: next_display_style, next: next, name: next_name}, _},
           previous:
             {%{
                delimiter: previous_display_style,
                previous: previous,
                name: previous_name
              }, _},
           should_close: {should_close, _},
           show_navigation: {show_navigation, _},
           split: {split, _},
           title: {title, _}
         } = menu,
         routes,
         _api_parameters
       ) do
    %{depth: page} = List.first(routes)

    # {0, 6}
    {min, max} = {split * (page - 1), page * split - 1}

    # [0, 1, 2, 3, 4, 5, 6]
    selection = Enum.into(min..max, [])

    # [{0, 0}, {1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 5}, {6, 6}]
    positions = selection |> Enum.with_index()

    menus =
      Enum.map(positions, fn x ->
        case Enum.at(Enum.reverse(menu_list), elem(x, 0)) do
          nil ->
            nil

          current_menu ->
            %{name: name} = current_menu
            "#{elem(x, 1) + 1 + min}#{delimiter_style}#{name}"
        end
      end)
      |> Enum.filter(fn value -> value != nil end)

    previous_navigation =
      cond do
        length(routes) == 1 and page == 1 ->
          ""

        length(routes) == 1 and page > 1 ->
          "\n" <> "#{previous}#{previous_display_style}#{previous_name}"

        length(routes) > 1 and should_close == false ->
          "\n" <> "#{previous}#{previous_display_style}#{previous_name}"

        length(routes) > 1 and should_close == true ->
          ""
      end

    next_navigation =
      cond do
        Enum.at(menu_list, max + 1) == nil -> ""
        length(routes) == 1 -> "\n#{next}#{next_display_style}#{next_name}"
        length(routes) > 1 -> " " <> "#{next}#{next_display_style}#{next_name}"
      end

    menu_string =
      cond do
        menus == [] and show_navigation == true ->
          "#{error}#{title}" <> previous_navigation <> next_navigation

        menus == [] and show_navigation == false ->
          "#{error}#{title}"

        menus != [] and show_navigation == true ->
          "#{error}#{title}\n" <> Enum.join(menus, "\n") <> previous_navigation <> next_navigation

        menus != [] and show_navigation == false ->
          "#{error}#{title}\n" <> Enum.join(menus, "\n")
      end

    {should_close, _} = menu.should_close
    {:ok, %{menu_string: menu_string, should_close: should_close}}
  end
end
