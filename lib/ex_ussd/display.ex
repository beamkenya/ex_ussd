defmodule ExUssd.Display do
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
      should_close: should_close,
      display_style: display_style,
      show_navigation: show_navigation
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

    previous_navigation =
      case length(routes) do
        1 ->
          case page do
            1 -> ""
            _ -> "\n" <> "#{previous}#{previous_display_style}#{previous_name}"
          end

        _ ->
          case should_close do
            false -> "\n" <> "#{previous}#{previous_display_style}#{previous_name}"
            true -> ""
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
      case menus do
        [] ->
          case show_navigation do
            true -> "#{error}#{title}" <> previous_navigation <> next_navigation
            false -> "#{error}#{title}"
          end

        _ ->
          case show_navigation do
            true ->
              "#{error}#{title}\n" <>
                Enum.join(menus, "\n") <> previous_navigation <> next_navigation

            false ->
              "#{error}#{title}\n" <> Enum.join(menus, "\n")
          end
      end

    {:ok, response}
  end
end
