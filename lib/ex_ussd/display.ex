defmodule ExUssd.Display do
  alias ExUssd.State.Registry

  @moduledoc """
  Rendering of Menu Struct into response string
  """

  @doc """
    Render's USSD string

    ## Params
  The function requires two keys as parameters
    `:menu` - takes current menu struct
    `:routes` - ExUssd.Routes routing list

    Returns string.

      ## Examples
        iex> defmodule MyHomeHandler do
        ...>   @behaviour ExUssd.Handler
        ...>   def handle_menu(menu, api_parameters) do
        ...>     menu |> Map.put(:title, "Welcome")
        ...>   end
        ...> end

        iex> initial_menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)
        iex> menu = ExUssd.Utils.call_menu_callback(initial_menu)
        iex> routes = ExUssd.Routes.get_route(%{text: "", service_code: "*544#"})

        iex> ExUssd.Display.generate(menu: menu, routes: routes)
        {:ok, "Welcome"}


        iex> defmodule ProductAHandler do
        ...>   @behaviour ExUssd.Handler
        ...>   def handle_menu(menu, api_parameters) do
        ...>     menu |> Map.put(:title, "selected product a")
        ...>   end
        ...> end

        iex> defmodule ProductBHandler do
        ...>   @behaviour ExUssd.Handler
        ...>   def handle_menu(menu, api_parameters) do
        ...>     menu |> Map.put(:title, "selected product b")
        ...>   end
        ...> end

        iex> defmodule MyHomeHandler do
        ...>   @behaviour ExUssd.Handler
        ...>   def handle_menu(menu, api_parameters) do
        ...>     menu
        ...>     |> Map.put(:title, "Welcome")
        ...>     |> Map.put(:menu_list,
        ...>        [
        ...>          ExUssd.Menu.render(name: "Product A", handler: ProductAHandler),
        ...>          ExUssd.Menu.render(name: "Product B", handler: ProductBHandler)
        ...>       ])
        ...>   end
        ...> end

        iex> initial_menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)
        iex> menu = ExUssd.Utils.call_menu_callback(initial_menu)
        iex> routes = ExUssd.Routes.get_route(%{text: "", service_code: "*544#"})

        iex> ExUssd.Display.generate(menu: menu, routes: routes)
        {:ok, "Welcome\\n1:Product A\\n2:Product B"}

  """
  def generate(menu: menu, routes: routes) do
    builder(menu, routes, %{}, "")
  end

  def generate(menu: menu, routes: routes, api_parameters: api_parameters, session_id: session_id) do
    builder(menu, routes, api_parameters, session_id)
  end

  defp builder(menu, routes, api_parameters, session_id) do
    %{
      title: title,
      error: error,
      split: split,
      menu_list: menu_list,
      next: %{name: next_name, input_match: next, display_style: next_display_style},
      previous: %{
        name: previous_name,
        input_match: previous,
        display_style: previous_display_style
      },
      home: %{
        name: home_name,
        input_match: home,
        display_style: home_display_style,
        enable: is_home_enable
      },
      should_close: should_close,
      display_style: display_style,
      show_navigation: show_navigation,
      top_navigation: top_navigation,
      bottom_navigation: bottom_navigation,
      page_menu: page_menu
    } = menu

    %{depth: page} = hd(routes)

    # {0, 6}
    {min, max} = {split * (page - 1), page * split - 1}

    # [0, 1, 2, 3, 4, 5, 6]
    selection = Enum.into(min..max, [])

    # [{0, 0}, {1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 5}, {6, 6}]
    positions = selection |> Enum.with_index()

    menus =
      Enum.map(positions, fn x ->
        case Enum.at(menu_list, elem(x, 0)) do
          nil ->
            nil

          current_menu ->
            %{name: name} = current_menu
            "#{elem(x, 1) + 1 + min}#{display_style}#{name}"
        end
      end)
      |> Enum.filter(fn value -> value != nil end)

    home_navigation =
      case is_home_enable do
        true -> " #{home}#{home_display_style}#{home_name}"
        false -> ""
      end

    previous_navigation =
      case length(routes) do
        1 ->
          case page do
            1 -> ""
            _ -> "\n" <> "#{previous}#{previous_display_style}#{previous_name}" <> home_navigation
          end

        _ ->
          case should_close do
            false ->
              "\n" <> "#{previous}#{previous_display_style}#{previous_name}" <> home_navigation

            true ->
              ""
          end
      end

    next_navigation =
      case Enum.at(menu_list, max + 1) do
        nil ->
          ""

        _ ->
          case length(routes) do
            1 -> "\n#{next}#{next_display_style}#{next_name}"
            _ -> " " <> "#{next}#{next_display_style}#{next_name}"
          end
      end

    response =
      case page_menu do
        true ->
          [current_route | _current_routes] = routes
          %{depth: depth, value: _} = current_route

          Enum.at(menu_list, depth - 1)
          |> case do
            nil ->
              [route | routes] = Registry.get(session_id)
              %{depth: _, value: value} = route
              new_depth = length(menu_list) + 1

              new_route = %{depth: new_depth, value: value}
              new_routes = [new_route | routes]
              Registry.set(session_id, new_routes)

              "#{error}" <> previous_navigation

            current_menu ->
              return_menu = current_menu.callback.(api_parameters)
              %{title: title} = return_menu
              {return_menu, "#{top_navigation}#{title}" <> bottom_navigation}
          end

        _ ->
          case menus do
            [] ->
              case show_navigation do
                true -> "#{error}#{title}" <> previous_navigation <> next_navigation
                false -> "#{error}#{top_navigation}#{title}" <> bottom_navigation
              end

            _ ->
              case show_navigation do
                true ->
                  "#{error}#{title}\n" <>
                    Enum.join(menus, "\n") <> previous_navigation <> next_navigation

                false ->
                  "#{error}#{top_navigation}#{title}\n" <>
                    Enum.join(menus, "\n") <> bottom_navigation
              end
          end
      end

    case response do
      {return_menu, menu_string} -> {return_menu, menu_string}
      menu_string -> {menu, menu_string}
    end
  end
end
