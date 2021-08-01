defmodule ExUssd.Nav do
  @moduledoc """
  USSD Nav module
  """

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
    nav_list: [],
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
  ## Creates a new Nav struct
  """
  def new(opts) do
    if Keyword.get(opts, :type) in [:home, :next, :back] do
      struct!(__MODULE__, Keyword.take(opts, @allowed_fields))
    else
      raise %ArgumentError{message: "Invalid USSD navigation type: #{Keyword.get(opts, :type)}"}
    end
  end

  @doc """
  ## convert the USSD navigation menu to string
  """

  def to_string(%ExUssd.Nav{} = nav, depth \\ 2, max \\ true) do
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
