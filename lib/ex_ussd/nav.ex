defmodule ExUssd.Nav do
  @moduledoc """
  USSD Nav module
  """

  @type t :: %__MODULE__{
          name: String.t(),
          match: String.t(),
          type: atom(),
          orientation: atom(),
          delimiter: String.t(),
          reverse: boolean(),
          top: integer(),
          bottom: integer(),
          right: integer(),
          left: integer(),
          show: boolean()
        }

  @enforce_keys [:name, :match, :type]

  defstruct [
    :name,
    :match,
    :type,
    orientation: :horizontal,
    delimiter: ":",
    reverse: false,
    top: 0,
    bottom: 0,
    right: 0,
    left: 0,
    show: true
  ]

  @allowed_fields [
    :type,
    :name,
    :match,
    :delimiter,
    :orientation,
    :reverse,
    :top,
    :bottom,
    :right,
    :left,
    :show
  ]

  @doc """
  Its used to create a new ExUssd Nav menu.

   - **`:type`** - The type of the menu. ExUssd supports 3 types of nav
      - :home - Go back to the initial menu
      - :back - Go back to the previous menu
      - :next - Go to the nested menu
   - **`:name`** - The name of the nav.
   - **`:match`** - The match string to match the nav. example when the user enters "0" for `:back` type, the match string is "0"
   - **`:delimiter`** - The delimiter to split the match string. default is ":"
   - **`:orientation`** - The orientation of the nav. default is :horizontal
   - **`:reverse`** - Reverse the order of the nav. default is false
   - **`:top`** - The top position of the nav. default is 0
   - **`:bottom`** - The bottom position of the nav. default is 0
   - **`:right`** - The right position of the nav. default is 0
   - **`:left`** - The left position of the nav. default is 0
   - **`:show`** - Show the nav. default is true. if false, the nav will not be shown in the menu

  ## Example 

  ```elixir
  iex> menu = ExUssd.new(name: "home") 
  iex> ExUssd.set(menu, nav: Nav.new(type: :next, name: "MORE", match: "98"))

  iex> menu = ExUssd.new(name: "home") 
  iex> ExUssd.set(menu, nav: [
      ExUssd.Nav.new(type: :home, name: "HOME", match: "00", reverse: true, orientation: :vertical)
      ExUssd.Nav.new(type: :back, name: "BACK", match: "0", right: 1),
      ExUssd.Nav.new(type: :next, name: "MORE", match: "98")
    ])
  ```
  """

  @spec new(keyword()) :: %ExUssd.Nav{}
  def new(opts) do
    if Keyword.get(opts, :type) in [:home, :next, :back] do
      struct!(__MODULE__, Keyword.take(opts, @allowed_fields))
    else
      raise %ArgumentError{message: "Invalid USSD navigation type: #{Keyword.get(opts, :type)}"}
    end
  end

  @doc """
   Convert the USSD navigation menu to string

  ## Example 

  ```elixir
  iex> Nav.new(type: :next, name: "MORE", match: "98") |> Nav.to_string()
  "MORE:98"

  iex> nav = [
        ExUssd.Nav.new(type: :home, name: "HOME", match: "00", reverse: true, orientation: :vertical),
        ExUssd.Nav.new(type: :back, name: "BACK", match: "0", right: 1),
        ExUssd.Nav.new(type: :next, name: "MORE", match: "98")
      ]
  iex> ExUssd.Nav.to_string(nav)
  "HOME:00
   BACK:0 MORE:98"
   ```
  """

  @spec to_string([ExUssd.Nav.t()]) :: String.t()
  def to_string(nav) when is_list(nav) do
    to_string(nav, 1, Enum.map(1..10, & &1), 0, 1, :vertical)
  end

  @spec to_string([ExUssd.Nav.t()], integer(), [ExUssd.t()], integer(), integer(), any()) ::
          String.t()
  def to_string(navs, depth, menu_list, max, level, orientation) when is_list(navs) do
    nav =
      navs
      |> Enum.reduce("", &reduce_nav(&1, &2, navs, menu_list, depth, max, level, orientation))
      |> String.trim_trailing()

    if String.starts_with?(nav, "\n") do
      nav
    else
      String.pad_leading(nav, String.length(nav) + 1, "\n")
      |> String.trim_trailing()
    end
  end

  @spec to_string(ExUssd.Nav.t(), integer(), integer(), any()) :: String.t()
  def to_string(
        %ExUssd.Nav{} = nav,
        depth \\ 2,
        opts \\ %{},
        level \\ 1,
        orientation \\ :vertical
      ) do
    menu_list = Map.get(opts, :menu_list, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    max = Map.get(opts, :max, 0)
    has_next = Enum.at(menu_list, max + 1)

    fun = fn
      _, %ExUssd.Nav{show: false} ->
        ""

      %{orientation: :vertical, depth: 1, has_next: nil, level: 1}, _nav ->
        ""

      %{orientation: :vertical, depth: 1, level: 1}, %ExUssd.Nav{type: :back} ->
        ""

      %{orientation: :vertical, depth: 1, level: 1}, %ExUssd.Nav{type: :home} ->
        ""

      %{orientation: :vertical, has_next: nil}, %ExUssd.Nav{type: :next} ->
        ""

      %{orientation: :horizontal, depth: 1, level: 1}, %ExUssd.Nav{type: :back} ->
        ""

      %{orientation: :horizontal, level: 1}, %ExUssd.Nav{type: :home} ->
        ""

      %{orientation: :horizontal, depth: depth, menu_length: menu_length},
      %ExUssd.Nav{type: :next}
      when depth >= menu_length ->
        ""

      _, %ExUssd.Nav{name: name, delimiter: delimiter, match: match, reverse: true} ->
        "#{match}#{delimiter}#{name}"

      _, %ExUssd.Nav{name: name, delimiter: delimiter, match: match} ->
        "#{name}#{delimiter}#{match}"
    end

    navigation =
      apply(fun, [
        %{
          orientation: orientation,
          depth: depth,
          has_next: has_next,
          level: level,
          max: max,
          menu_length: length(menu_list)
        },
        nav
      ])

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

  @spec padding(String.t(), atom(), ExUssd.Nav.t()) :: String.t()
  defp padding(string, direction, nav)

  defp padding(string, :left, %ExUssd.Nav{left: amount}) do
    String.pad_leading(string, String.length(string) + amount)
  end

  defp padding(string, :right, %ExUssd.Nav{orientation: :horizontal, right: amount}) do
    String.pad_trailing(string, String.length(string) + amount)
  end

  defp padding(string, :right, %ExUssd.Nav{orientation: :vertical}), do: string

  defp padding(string, :top, %ExUssd.Nav{orientation: :vertical, top: amount}) do
    padding = String.duplicate("\n", 1 + amount)
    IO.iodata_to_binary([padding, string])
  end

  defp padding(string, :top, %ExUssd.Nav{top: amount}) do
    padding = String.duplicate("\n", amount)
    IO.iodata_to_binary([padding, string])
  end

  defp padding(string, :bottom, %ExUssd.Nav{orientation: :vertical, bottom: amount}) do
    padding = String.duplicate("\n", 1 + amount)
    IO.iodata_to_binary([string, padding])
  end

  defp padding(string, :bottom, %ExUssd.Nav{orientation: :horizontal}), do: string

  defp reduce_nav(%{type: type}, acc, nav, menu_list, depth, max, level, orientation) do
    navigation =
      to_string(
        Enum.find(nav, &(&1.type == type)),
        depth,
        %{max: max, menu_list: menu_list},
        level,
        orientation
      )

    IO.iodata_to_binary([acc, navigation])
  end
end
