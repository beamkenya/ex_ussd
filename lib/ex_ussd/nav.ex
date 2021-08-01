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

  @doc """
    ## Create a new USSD navigation menu
    ## Example:
    iex> [
            ExUssd.Nav.new(type: :home, name: "Home", match: "00", delimiter: ": ", top: 1, reverse: true, orientation: :vertical),
            ExUssd.Nav.new(type: :next, name: "Next", match: "98", delimiter: " -> ", orientation: :horizontal),
            ExUssd.Nav.new(type: :back, name: "Back", match: "0", delimiter: " -> ", right: 2, orientation: :horizontal)     
          ]
      "
       00: Home
       Next -> 98 Back -> 0
      "
  """

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

  def new(opts) do
    if Keyword.get(opts, :type) in [:home, :next, :back] do
      struct!(__MODULE__, Keyword.take(opts, @allowed_fields))
    else
      raise %ArgumentError{message: "Invalid USSD navigation type: #{Keyword.get(opts, :type)}"}
    end
  end
end
