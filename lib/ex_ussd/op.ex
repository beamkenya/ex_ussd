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
  Returns the ExUssd struct for the given keyword list opts.

  ## Options
  These options are required;
  * `:opts` — keyword lists includes (name, handler)

  ## Example
    iex> ExUssd.new(name: "Home", handler: MyHomeHandler, orientation: :vertical)
  """
  def new(opts) do
    fun = fn opts ->
      if Keyword.keyword?(opts) do
        struct!(ExUssd, Keyword.take(opts, [:data, :handler, :name, :orientation]))
      end
    end

    with {:error, error} <- apply(fun, [opts]) |> validate_new(opts) do
      raise ExUssd.Error, message: error
    end
  end

  defp validate_new(nil, opts) do
    {:error, "Expected a keyword list opts found #{inspect(opts)}"}
  end

  defp validate_new(menu, opts) do
    fun = fn opts, key ->
      if not Keyword.has_key?(opts, key) do
        message = "Expected #{inspect(key)} found #{inspect(Keyword.keys(opts))}"
        {:error, message}
      end
    end

    Enum.reduce_while([:name, :handler], 0, fn key, _ ->
      case apply(fun, [opts, key]) do
        nil -> {:cont, menu}
        error -> {:halt, error}
      end
    end)
  end

  @doc """
  Sets the allowed fields on ExUssd struct.

  ## Options
  These options are required;
  * `:menu` — ExUssd Menu
  * `:opts` — Keyword list includes @allowed_fields

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
        "Expected field in allowable fields #{inspect(@allowed_fields)} found #{inspect(Keyword.keys(opts))}"

      raise ExUssd.Error, message: message
    end
  end

  @doc """
  Add menu to ExUssd menu list.

  ## Options
  These options are required;
  * `:menu` — ExUssd Menu
  * `:menu` — ExUssd child menu to add to menu list

  ## Example
    iex> menu = ExUssd.new(name: "Home", handler: MyHomeHandler)
    iex> menu |> ExUssd.add(ExUssd.new(name: "Product A", handler: ProductAHandler)))


  Add menus to to ExUssd menu list.
  Note: The menus share one handler

  ## Options
  These options are required;
  * `:menu` — ExUssd Menu
  * `:opts` — Keyword list includes (menus, handler)

  ## Example
    iex> menu = ExUssd.new(name: "Home", handler: MyHomeHandler, orientation: :horizontal)
    iex> menu |> ExUssd.add(menus: [ExUssd.new(name: "Product A")], handler: ProductAHandler))
  """

  def add(%ExUssd{orientation: :vertical} = menu, %ExUssd{} = child) do
    fun = fn menu, child ->
      Map.get_and_update(menu, :menu_list, fn menu_list -> {:ok, [child | menu_list]} end)
    end

    with {:ok, menu} <- apply(fun, [menu, child]), do: menu
  end

  def add(menu, opts) do
    opts =
      opts
      |> Keyword.take([:menus, :handler])
      |> Enum.into(%{})

    orientation = Map.get(menu, :orientation)

    add(orientation, opts, menu)
  end

  defp add(:vertical, %{menus: menus, handler: handler}, menu) do
    menu_list = Enum.map(menus, fn menu -> Map.put(menu, :handler, handler) end)
    Map.put(menu, :menu_list, Enum.reverse(menu_list))
  end

  defp add(:horizontal, %{menus: menus, handler: handler}, menu) do
    menu_list = Enum.map(menus, fn menu -> Map.put(menu, :handler, handler) end)
    Map.put(menu, :menu_list, menu_list)
  end

  defp add(_, %{menus: menus, handler: _}, _) when not is_list(menus) do
    message = "menus should be a list, found #{inspect(menus)}"
    raise ExUssd.Error, message: message
  end

  defp add(_, %{menus: menus, handler: _}, _) when menus == [] do
    message = "menus should not be empty"
    raise ExUssd.Error, message: message
  end

  defp add(_, %{menus: _}, _) do
    message = "handler not provided"
    raise ExUssd.Error, message: message
  end

  defp add(_, _, _) do
    message = "menus not provided"
    raise ExUssd.Error, message: message
  end
end
