defmodule ExUssd.Display do
  @moduledoc false

  @doc """
  Its used to tranform ExUssd menu struct to string.

  ## Parameters

    - `menu` - menu to transform to string
    - `route` - route
    - `opts` - optional session args

  ## Examples

      iex> menu = ExUssd.new(name: "home", resolve: fn menu, _payload, _metadata -> menu |> ExUssd.set(title: "Welcome") end)
      iex> ExUssd.Display.to_string(menu, ExUssd.Route.get_route(%{text: "*544#", service_code: "*544#"}))
      {:ok, %{menu_string: "Welcome", should_close: false}}
  """

  def to_string(_, _, opts \\ [])

  @spec to_string(%ExUssd{orientation: :horizontal}, map()) ::
          {:ok, %{menu_string: String.t(), should_close: boolean()}}
  def to_string(
        %ExUssd{
          orientation: :horizontal,
          error: error,
          delimiter: delimiter,
          menu_list: menu_list,
          nav: nav,
          should_close: should_close,
          default_error: default_error
        },
        %{route: route},
        opts
      ) do
    session = Keyword.get(opts, :session_id)

    %{depth: depth} = List.first(route)

    total_length = Enum.count(menu_list)

    menu_list = get_menu_list(menu_list, opts)

    navigation = ExUssd.Nav.to_string(nav, depth + 1, menu_list, depth - 1, length(route))

    should_close =
      if depth == total_length do
        should_close
      else
        false
      end

    menu_string =
      case Enum.at(menu_list, depth - 1) do
        %ExUssd{name: name} ->
          if should_close do
            IO.iodata_to_binary(["#{depth}", delimiter, "#{total_length}", "\n", name])
          else
            IO.iodata_to_binary(["#{depth}", delimiter, "#{total_length}", "\n", name, navigation])
          end

        _ ->
          ExUssd.Registry.set_depth(session, total_length + 1)
          IO.iodata_to_binary([default_error, navigation])
      end

    error = if error != true, do: error

    {:ok,
     %{menu_string: IO.iodata_to_binary(["#{error}", menu_string]), should_close: should_close}}
  end

  @spec to_string(ExUssd.t(), map(), keyword()) ::
          {:ok, %{menu_string: String.t(), should_close: boolean()}}
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
        },
        %{route: route},
        opts
      ) do
    %{depth: depth} = List.first(route)

    # {0, 6}
    {min, max} = {split * (depth - 1), depth * split - 1}

    # [0, 1, 2, 3, 4, 5, 6]
    selection = Enum.into(min..max, [])

    menu_list = get_menu_list(menu_list, opts)

    menus =
      selection
      |> Enum.with_index()
      |> Enum.map(&transform(menu_list, min, delimiter, &1))
      |> Enum.reject(&is_nil(&1))

    navigation = ExUssd.Nav.to_string(nav, depth, menu_list, max, length(route))
    error = if error != true, do: error

    title_error = IO.iodata_to_binary(["#{error}", "#{title}"])

    show_navigation =
      if should_close do
        false
      else
        show_navigation
      end

    menu_string =
      cond do
        Enum.empty?(menus) and show_navigation == false ->
          title_error

        Enum.empty?(menus) and show_navigation == true ->
          IO.iodata_to_binary([title_error, navigation])

        show_navigation == false ->
          IO.iodata_to_binary([title_error, "\n", Enum.join(menus, "\n")])

        show_navigation == true ->
          IO.iodata_to_binary([title_error, "\n", Enum.join(menus, "\n"), navigation])
      end

    {:ok, %{menu_string: menu_string, should_close: should_close}}
  end

  @spec transform([ExUssd.t()], integer(), String.t(), {integer(), integer()}) :: nil | binary()
  defp transform(menu_list, min, delimiter, {position, index}) do
    case Enum.at(menu_list, position) do
      %ExUssd{name: name} ->
        "#{index + 1 + min}#{delimiter}#{name}"

      nil ->
        nil
    end
  end

  defp get_menu_list(menu_list, opts) do
    menu_list
    |> Enum.map(fn %{name: name} = menu ->
      if String.equivalent?(name, "") do
        ExUssd.Executer.execute_navigate(menu, Map.new(opts))
      else
        menu
      end
    end)
    |> Enum.reverse()
  end
end
