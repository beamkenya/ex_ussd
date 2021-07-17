defmodule ExUssd.Op do
  @moduledoc """
  Contains all ExUssd Public API functions
  """

  @allowed_fields [
    :error,
    :title,
    :next,
    :previous,
    :should_close,
    :split,
    :delimiter,
    :default_error,
    :show_navigation,
    :data
  ]

  @doc """
  Returns the ExUssd struct for the given keyword list args.

  ## Options
  These options are required;
  * `:args` — keyword lists

  ## Example
    iex> ExUssd.new(name: "Home", handler: MyHomeHandler)
  """
  def new(args) do
    fun = fn args ->
      if Keyword.keyword?(args) do
        struct!(ExUssd, Keyword.take(args, [:handler, :name]))
      end
    end

    with nil <- apply(fun, [args]) do
      message = "Expected a keyword list found #{IO.inspect(args)}"
      raise ExUssd.Error, message: message
    end
  end

  @doc """
  Sets the allowed fields on ExUssd struct.

  ## Options
  These options are required;
  * `:menu` — ExUssd Menu
  * `:opts` — Keyword list field value

  ## Example
    iex> menu = ExUssd.new(name: "Home", handler: MyHomeHandler)
    iex> menu |> ExUssd.set(title: "Welcome", should_close: true)
  """

  def set(%ExUssd{} = menu, opts) do
    fun = fn menu, opts ->
      if MapSet.subset?(MapSet.new(Keyword.keys(opts)), MapSet.new(@allowed_fields)) do
        Map.merge(menu, Enum.into(opts, %{}))
      end
    end

    with nil <- apply(fun, [menu, opts]) do
      message =
        "Expected field allowable fields #{inspect(@allowed_fields)} found #{inspect(Keyword.keys(opts))}"

      raise ExUssd.Error, message: message
    end
  end
end
