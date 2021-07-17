defmodule ExUssd.Op do
  alias ExUssd.Op

  @moduledoc """
  Contains all ExUssd Public API functions
  """

  @doc """
  Returns the ExUssd struct for the given keyword list args.

  ## Options
  These options are required;
  * `:args` — keyword lists

  ## Example
    iex> ExUssd.new!(name: "Home", handler: MyHomeHandler)
  """
  def new!(args) do
    fun = fn args ->
      if Keyword.keyword?(args) do
        struct!(ExUssd, Keyword.take(args, [:handler, :name]))
      end
    end

    Op.new!(fun, [args])
  end

  def new!(fun, args) when is_function(fun) do
    with nil <- apply(fun, args) do
      raise ExUssd.Error, message: "Expected a keyword list found #{IO.inspect(args)}"
    end
  end
end
