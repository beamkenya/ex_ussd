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
    iex> ExUssd.new(orientation: :vertical, name: "home", resolve: MyHomeResolver)
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

    with {:error, message} <- apply(fun, [opts]) |> validate_new(opts) do
      raise %ArgumentError{message: message}
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

    Enum.reduce_while([:name], menu, fn key, _ ->
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
    iex> menu = ExUssd.new(name: "Home", resolve: &HomeResolver.welcome_menu/3)
    iex> menu |> ExUssd.set(title: "Welcome", data: %{a: 1}, should_close: true)
    iex> menu |> ExUssd.set(nav: ExUssd.Nav.new(type: :back, name: "BACK", match: "*"))
    iex> menu |> ExUssd.set(nav: [ExUssd.Nav.new(type: :back, name: "BACK", match: "*")])
  """

  def set(%ExUssd{} = menu, nav: %ExUssd.Nav{type: type} = nav)
      when type in [:home, :next, :back] do
    case Enum.find_index(menu.nav, fn nav -> nav.type == type end) do
      nil ->
        menu

      index ->
        Map.put(menu, :nav, List.update_at(menu.nav, index, fn _ -> nav end))
    end
  end

  def set(%ExUssd{}, nav: %ExUssd.Nav{type: type}) do
    raise %ArgumentError{message: "nav has unknown type #{inspect(type)}"}
  end

  def set(%ExUssd{} = menu, nav: nav) when is_list(nav) do
    if Enum.all?(nav, &is_struct(&1, ExUssd.Nav)) do
      Map.put(menu, :nav, Enum.uniq_by(nav ++ menu.nav, fn n -> n.type end))
    else
      raise %ArgumentError{
        message: "nav should be a list of ExUssd.Nav struct, found #{inspect(nav)}"
      }
    end
  end

  def set(%ExUssd{} = menu, opts) do
    fun = fn menu, opts ->
      if MapSet.subset?(MapSet.new(Keyword.keys(opts)), MapSet.new(@allowed_fields)) do
        Map.merge(menu, Enum.into(opts, %{}))
      end
    end

    with nil <- apply(fun, [menu, opts]) do
      message =
        "Expected field in allowable fields #{inspect(@allowed_fields)} found #{inspect(Keyword.keys(opts))}"

      raise %ArgumentError{message: message}
    end
  end

  @doc """
  Add menu to ExUssd menu list.

  ## Options
  These options are required;
  * `:menu` — ExUssd Menu
  * `:child` — ExUssd add to menu list
  * `:menus` — List of ExUssd menu
  * `:opts` — Keyword list includes (resolve)

  ## Example
    iex> menu = ExUssd.new(name: "Home", resolve: MyHomeResolver)
    iex> ExUssd.add(menu, ExUssd.new(name: "Product A", resolve: ProductResolver)))

  Add menus to to ExUssd menu list.
  Note: The menus share one resolver

  ## Example
    iex> menu = ExUssd.new(orientation: :vertical, name: "Home", resolve: MyHomeResolver)
    iex> menu |> ExUssd.add([ExUssd.new(name: "Nairobi", data: %{city: "Nairobi", code: 47})], resolve: &CountyResolver.city_menu/3))
  """

  def add(_, _, opts \\ [])

  def add(%ExUssd{} = menu, %ExUssd{} = child, _opts) do
    fun = fn menu, child ->
      Map.get_and_update(menu, :menu_list, fn menu_list -> {:ok, [child | menu_list]} end)
    end

    with {:ok, menu} <- apply(fun, [menu, child]), do: menu
  end

  def add(%ExUssd{} = menu, menus, opts) do
    resolve = Keyword.get(opts, :resolve)

    fun = fn
      _menu, menus, _ when not is_list(menus) ->
        {:error, "menus should be a list, found #{inspect(menus)}"}

      _menu, menus, _ when menus == [] ->
        {:error, "menus should not be empty, found #{inspect(menu)}"}

      %ExUssd{orientation: :vertical}, _menus, nil ->
        {:error, "resolve callback not found in opts keyword list"}

      %ExUssd{} = menu, menus, resolve ->
        if Enum.all?(menus, &is_struct(&1, ExUssd)) do
          menu_list = Enum.map(menus, fn menu -> Map.put(menu, :resolve, resolve) end)
          Map.put(menu, :menu_list, Enum.reverse(menu_list))
        else
          {:error, "menus should be a list of ExUssd menus, found #{inspect(menus)}"}
        end
    end

    with {:error, message} <- apply(fun, [menu, menus, resolve]) do
      raise %ArgumentError{message: message}
    end
  end
end
