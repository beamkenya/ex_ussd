defmodule ExUssd.Nav do
  @moduledoc """
  USSD Nav module
  """

  @type t :: %__MODULE__{
          name: String.t(),
          match: String.t(),
          type: term(),
          orientation: term(),
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

  ## Parameters

    - `opts` - Nav arguments
    
  ## Example 

  iex> ExUssd.new(name: "home") |> ExUssd.set(Nav.new(type: :next, name: "MORE", match: "98"))

  iex> ExUssd.new(name: "home") 
      |> ExUssd.set([
       ExUssd.Nav.new(
        type: :home,
        name: "HOME",
        match: "00",
        reverse: true,
        orientation: :vertical
      ),
      ExUssd.Nav.new(type: :back, name: "BACK", match: "0", right: 1),
      ExUssd.Nav.new(type: :next, name: "MORE", match: "98")
    ])
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

   ## Parameters
    - `nav` - Nav Struct
    - `depth` - depth of the nav menu
    - `max` - max value of the menu list

  ## Example 

  iex> Nav.new(type: :next, name: "MORE", match: "98") |> Nav.to_string()
  "MORE:98"
  """

  @spec to_string(ExUssd.Nav.t(), integer(), integer()) :: String.t()
  def to_string(%ExUssd.Nav{} = nav, depth \\ 2, max \\ 999) do
    fun = fn
      _, %ExUssd.Nav{show: false} ->
        ""

      %{depth: 1, max: nil}, _nav ->
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

  @spec padding(String.t(), term(), ExUssd.Nav.t()) :: String.t()
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
end
