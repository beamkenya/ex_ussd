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
  * `:opts` — keyword lists includes (name, resolve)

  ## Example
    iex> ExUssd.new(orientation: :vertical, name: "home", resolve: MyHomeHandler)
    iex> ExUssd.new(orientation: :horizontal, name: "home", resolve: fn menu, _api_parameters, _metadata -> menu |> ExUssd.set(title: "Welcome") end)
  """
  def new(opts) do
    fun = fn opts ->
      if Keyword.keyword?(opts) do
        {_, opts} =
          Keyword.get_and_update(opts, :name, fn name ->
            {name, Utils.truncate(name, length: 140, omission: "...")}
          end)

        struct!(ExUssd, Keyword.take(opts, [:data, :resolve, :name, :orientation]))
      end
    end

    with {:error, error} <- apply(fun, [opts]) |> validate_new(opts) do
      throw(error)
    end
  end

  defp validate_new(nil, opts) do
    {:error, "Expected a keyword list opts found #{inspect(opts)}"}
  end

  defp validate_new(%ExUssd{orientation: orientation} = menu, opts)
       when orientation in [:vertical, :horizontal] do
    fun = fn opts, key ->
      if not Keyword.has_key?(opts, key) do
        {:error, "Expected #{inspect(key)} in opts, found #{inspect(Keyword.keys(opts))}"}
      end
    end

    Enum.reduce_while([:name, :resolve], 0, fn key, _ ->
      case apply(fun, [opts, key]) do
        nil -> {:cont, menu}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_new(%ExUssd{orientation: orientation}, _opts) do
    {:error, "Unknown orientation value, #{inspect(orientation)}"}
  end

  @doc """
  Sets the allowed fields on ExUssd struct.

  ## Options
  These options are required;
  * `:menu` — ExUssd Menu
  * `:opts` — Keyword list includes @allowed_fields

  ## Example
    iex> menu = ExUssd.new(name: "Home", resolve: fn menu, _, _ -> menu |> ExUssd.set(title: "Welcome") end)
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
  * `:opts` — Keyword list includes (menus, resolver)

  ## Example
    iex> menu = ExUssd.new(name: "Home", resolve: MyHomeHandler)
    iex> ExUssd.add(menu, ExUssd.new(name: "Product A", resolve: ProductAHandler)))

  Add menus to to ExUssd menu list.
  Note: The menus share one resolver

  ## Example
    iex> menu = ExUssd.new(orientation: :horizontal, name: "Home", resolve: MyHomeHandler)
    iex> menu |> ExUssd.add(menus: [ExUssd.new(name: "Nairobi", data: %{city: "Nairobi", code: 47})], resolve: ProductAHandler))
  """

  def add(%ExUssd{} = menu, %ExUssd{} = child) do
    fun = fn menu, child ->
      Map.get_and_update(menu, :menu_list, fn menu_list -> {:ok, [child | menu_list]} end)
    end

    with {:ok, menu} <- apply(fun, [menu, child]), do: menu
  end

  def add(%ExUssd{} = menu, opts) when is_list(opts) do
    fun = fn
      menu, %{menus: menus, resolve: resolve} when is_list(menus) ->
        menu_list = Enum.map(menus, fn menu -> Map.put(menu, :resolve, resolve) end)
        Map.put(menu, :menu_list, Enum.reverse(menu_list))

      _, %{menus: menus, resolve: _} when menus == [] ->
        {:error, "menus should not be empty"}

      _, %{menus: menus, resolve: _} when not is_list(menus) ->
        {:error, "menus should be a list, found #{inspect(menus)}"}

      _, %{menus: _} ->
        {:error, "resolve not provided"}

      _, _ ->
        {:error, "menus not provided"}
    end

    opts =
      opts
      |> Keyword.take([:menus, :resolve])
      |> Enum.into(%{})

    with {:error, error} <- apply(fun, [menu, opts]) do
      throw(error)
    end
  end
end
