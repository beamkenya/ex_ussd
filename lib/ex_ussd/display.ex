defmodule ExUssd.Display do
  @moduledoc """
  This module provides the display functions for the ExUssd lib.
  """

  #   def to_string(
  #         %ExUssd{
  #           orientation: :horizontal,
  #           delimiter: delimiter,
  #           error: error,
  #           menu_list: menu_list,
  #           nav: nav,
  #           should_close: should_close,
  #           show_navigation: show_navigation,
  #           split: split,
  #           title: title
  #         } = menu,
  #         %ExUssd.Route{route: route},
  #         opts \\ []
  #       ) do
  #     session = Keyword.get(opts, :session)
  #     navigation =
  #       nav
  #       |> Enum.reduce("", fn %{type: type}, acc ->
  #         navigation =
  #           get_navigation(
  #             menu,
  #             depth,
  #             Enum.at(menu_list, max + 1),
  #             Enum.find(nav, &(&1.type == type))
  #           )

  #         IO.iodata_to_binary([acc, navigation])
  #       end)
  #       |> String.trim()

  #   end

  def to_string(
        %ExUssd{
          orientation: :vertical,
          delimiter: delimiter,
          error: error,
          menu_list: menu_list,
          nav: nav,
          should_close: should_close,
          show_navigation: show_navigation,
          split: split,
          title: title
        } = menu,
        %ExUssd.Route{route: route},
        opts \\ []
      ) do
    %{depth: depth} = List.first(route)

    # {0, 6}
    {min, max} = {split * (depth - 1), depth * split - 1}

    # [0, 1, 2, 3, 4, 5, 6]
    selection = Enum.into(min..max, [])
    menu_list = Enum.reverse(menu_list)

    menus =
      selection
      |> Enum.with_index()
      |> Enum.map(&transform(menu_list, min, delimiter, &1))
      |> Enum.reject(&is_nil(&1))

    navigation =
      nav
      |> Enum.reduce("", fn %{type: type}, acc ->
        navigation =
          get_navigation(
            menu,
            depth,
            Enum.at(menu_list, max + 1),
            Enum.find(nav, &(&1.type == type))
          )

        IO.iodata_to_binary([acc, navigation])
      end)
      |> String.trim()

    title_error = IO.iodata_to_binary(["#{error}", title])

    menu_string =
      cond do
        Enum.empty?(menus) and show_navigation == false ->
          title_error

        Enum.empty?(menus) and show_navigation == true ->
          IO.iodata_to_binary([title_error, navigation])

        show_navigation == false ->
          IO.iodata_to_binary(["#{title_error}\n", Enum.join(menus, "\n")])

        show_navigation == true ->
          IO.iodata_to_binary(["#{title_error}\n", Enum.join(menus, "\n"), navigation])
      end

    {:ok, %{menu_string: menu_string, should_close: should_close}}
  end

  defp transform(menu_list, min, delimiter, {position, index}) do
    case Enum.at(menu_list, position) do
      %ExUssd{name: name} ->
        "#{index + 1 + min}#{delimiter}#{name}"

      nil ->
        nil
    end
  end

  def get_navigation(
        %ExUssd{should_close: should_close},
        depth,
        max,
        %ExUssd.Nav{orientation: orientation} = nav
      ) do
    fun = fn
      _, %ExUssd.Nav{show: false} ->
        ""

      %{depth: 1}, _nav ->
        ""

      %{max: nil}, %ExUssd.Nav{type: :next} ->
        ""

      _, %ExUssd.Nav{name: name, delimiter: delimiter, match: match, reverse: true} ->
        "#{match}#{delimiter}#{name}"

      _, %ExUssd.Nav{name: name, delimiter: delimiter, match: match} ->
        "#{name}#{delimiter}#{match}"
    end

    navigation = apply(fun, [%{depth: depth, max: max}, nav])

    if String.equivalent?(navigation, "") do
      navigation
    else
      navigation
      |> padding(:left, nav)
      |> padding(:right, nav)
      |> padding(:top, nav)
      |> padding(:bottom, nav)
    end
  end

  defp padding(string, :left, %ExUssd.Nav{left: amount}) do
    String.pad_leading(string, String.length(string) + amount)
  end

  defp padding(string, :right, %ExUssd.Nav{orientation: :horizontal, right: amount}) do
    String.pad_trailing(string, String.length(string) + amount)
  end

  defp padding(string, :right, %ExUssd.Nav{orientation: :vertical}), do: string

  defp padding(string, :top, %ExUssd.Nav{top: amount}) do
    padding = String.duplicate("\n", amount)
    IO.iodata_to_binary([padding, string])
  end

  defp padding(string, :bottom, %ExUssd.Nav{orientation: :vertical, bottom: amount}) do
    padding = String.duplicate("\n", 1 + amount)
    IO.iodata_to_binary([string, padding])
  end

  defp padding(string, :bottom, %ExUssd.Nav{orientation: :horizontal}), do: string
end
