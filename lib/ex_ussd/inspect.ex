defimpl Inspect, for: ExUssd do
  def inspect(
        %ExUssd{
          split: {split, _},
          default_error: default_error,
          orientation: orientation,
          title: {title, _},
          show_navigation: {show_navigation, _},
          should_close: {should_close, _},
          menu_list: {menu_list, _},
          data: data
        },
        _opts
      ) do
    menu_list =
      menu_list
      |> Enum.with_index()
      |> Enum.map(fn {%ExUssd{name: name}, index} -> "#{index + 1}: #{name}" end)
      |> Enum.join(", ")

    "#ExUssd<orientation: #{orientation}, default_error: #{default_error}, menu_list: [#{
      menu_list
    }], split: #{split}, title: #{title}, show_navigation: #{show_navigation}, should_close: #{
      should_close
    }, data: #{inspect(data)}>"
  end
end
