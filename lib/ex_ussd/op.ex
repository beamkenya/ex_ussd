defmodule ExUssd.Op do
  @moduledoc """
  Contains all ExUssd Public API functions
  """
  alias ExUssd.Utils

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
    iex> ExUssd.new(name: "aasd ...", handler: MyHomeHandler, orientation: :vertical)
  """
  def new(opts) do
    fun = fn opts ->
      if Keyword.keyword?(opts) do
        {_, opts} =
          Keyword.get_and_update(opts, :name, fn name ->
            {name, Utils.truncate(name, length: 140, omission: "...")}
          end)

        struct!(ExUssd, Keyword.take(opts, [:data, :handler, :name, :orientation]))
      end
    end

    with {:error, error} <- apply(fun, [opts]) |> validate_new(opts) do
      throw(error)
    end
  end

  defp validate_new(nil, opts) do
    {:error, "Expected a keyword list opts found #{inspect(opts)}"}
  end

  defp validate_new(%ExUssd{} = menu, opts) do
    fun = fn opts, key ->
      if not Keyword.has_key?(opts, key) do
        {:error, "Expected #{inspect(key)} in opts, found #{inspect(Keyword.keys(opts))}"}
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
    iex> menu = ExUssd.new(name: "Home", handler: fn menu, _, _ -> menu |> ExUssd.set(title: "Welcome") end)
    iex> menu |> ExUssd.set(title: "Welcome", data: %{a: 1}, should_close: true)
  """

  def set(%ExUssd{} = menu, opts) do
    fun = fn menu, opts ->
      if MapSet.subset?(MapSet.new(Keyword.keys(opts)), MapSet.new(@allowed_fields)) do
        Map.merge(menu, Enum.into(opts, %{}))
      end
    end

    with nil <- apply(fun, [menu, opts]) do
      throw(
        "Expected field in allowable fields #{inspect(@allowed_fields)} found #{inspect(Keyword.keys(opts))}"
      )
    end
  end

  @doc """
  Add menu to ExUssd menu list.

  ## Options
  These options are required;
  * `:menu` — ExUssd Menu
  * `:menu` — ExUssd add to menu list
  * `:opts` — Keyword list includes (menus, handler)

  ## Example
    iex> menu = ExUssd.new(name: "Home", handler: MyHomeHandler)
    iex> ExUssd.add(menu, ExUssd.new(name: "Product A", handler: ProductAHandler)))

  Add menus to to ExUssd menu list.
  Note: The menus share one handler

  ## Example
    iex> menu = ExUssd.new(name: "Home", handler: MyHomeHandler, orientation: :horizontal)
    iex> menu |> ExUssd.add(menus: [ExUssd.new(name: "Nairobi", data: %{city: "Nairobi", code: 47})], handler: ProductAHandler))
  """

  def add(%ExUssd{orientation: orientation} = menu, %ExUssd{} = child) do
    fun = fn orientation, menu, child ->
      if Enum.member?([:horizontal, :vertical], orientation) do
        Map.get_and_update(menu, :menu_list, fn menu_list -> {:ok, [child | menu_list]} end)
      end
    end

    with {:error, error} <- apply(fun, [orientation, menu, child]) |> validate_add(orientation) do
      throw(error)
    end
  end

  def add(%ExUssd{orientation: orientation} = menu, opts) when is_list(opts) do
    fun = fn orientation, menu, opts ->
      if Enum.member?([:horizontal, :vertical], orientation) do
        with %ExUssd{} = menu <- validate_add(menu, opts) do
          {:ok, menu}
        end
      end
    end

    opts =
      opts
      |> Keyword.take([:menus, :handler])
      |> Enum.into(%{})

    with {:error, error} <- apply(fun, [orientation, menu, opts]) |> validate_add(orientation) do
      throw(error)
    end
  end

  defp validate_add({:ok, menu}, orientation) when is_atom(orientation), do: menu

  defp validate_add(nil, orientation) when is_atom(orientation),
    do: {:error, "Unknown orientation value, #{inspect(orientation)}"}

  defp validate_add(%ExUssd{} = menu, %{menus: menus, handler: handler}) do
    menu_list = Enum.map(menus, fn menu -> Map.put(menu, :handler, handler) end)
    Map.put(menu, :menu_list, Enum.reverse(menu_list))
  end

  defp validate_add(_, %{menus: menus, handler: _}),
    do: {:error, "menus should be a list, found #{inspect(menus)}"}

  defp validate_add(_, %{menus: menus, handler: _}) when not is_list(menus),
    do: {:error, "menus should be a list, found #{inspect(menus)}"}

  defp validate_add(_, %{menus: menus, handler: _}) when menus == [],
    do: {:error, "menus should not be empty"}

  defp validate_add(_, %{menus: _}), do: {:error, "handler not provided"}

  defp validate_add(_, _), do: {:error, "menus not provided"}
end
