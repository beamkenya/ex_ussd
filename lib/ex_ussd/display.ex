defmodule ExUssd.Display do
  def generate(menu: menu, routes: routes) do
    %{
      title: title,
      error: error,
      split: split,
      menu_list: menu_list,
      show_options: show_options,
      next: next,
      previous: previous,
      should_close: should_close,
      display_style: display_style,
      show_navigation: show_navigation
    } = menu

    %{depth: page} = hd(routes)

    {min, max} =
      case show_options do
        false -> {split * (page - 1) + 1_000_000, page * split + 1_000_000}
        true -> {split * (page - 1), page * split - 1}
      end

    selection = Enum.into(min..max, [])
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
            _ -> "\n" <> "#{previous}#{display_style}BACK"
          end

        _ ->
          case show_options do
            false ->
              ""

            _ ->
              case should_close do
                false -> "\n" <> "#{previous}#{display_style}BACK"
                true -> ""
              end
          end
      end

    next_navigation =
      case Enum.at(menu_list, max + 1) do
        nil ->
          ""

        _ ->
          case show_options do
            false ->
              ""

            _ ->
              case length(routes) do
                1 -> "\n#{next}#{display_style}MORE"
                _ -> " " <> "#{next}#{display_style}MORE"
              end
          end
      end

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
  end
end
