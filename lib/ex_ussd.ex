defmodule ExUssd do
  defstruct [
    :name,
    :handler,
    :title,
    :parent,
    :data,
    :error,
    split: 7,
    show_navigation: true,
    should_close: false,
    delimiter: ":",
    default_error: "Invalid Choice\n",
    orientation: :vertical,
    menu_list: []
  ]

  defdelegate new!(opts), to: ExUssd.Op
end
