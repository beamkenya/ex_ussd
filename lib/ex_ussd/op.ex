defmodule ExUssd.Op do
  @moduledoc false
  alias ExUssd.{Display, Utils}

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
    :data,
    :resolve,
    :orientation,
    :name,
    :nav
  ]

  @doc """
  Add menu to ExUssd menu list.
  """
  @spec add(ExUssd.t(), ExUssd.t() | [ExUssd.t()], keyword()) :: ExUssd.t()
  def add(_, _, opts \\ [])

  def add(%ExUssd{} = menu, %ExUssd{} = child, _opts) do
    fun = fn
      %ExUssd{data: data} = menu, %ExUssd{navigate: navigate} = child
      when is_function(navigate, 2) ->
        Map.get_and_update(menu, :menu_list, fn menu_list ->
          {:ok, [%{child | data: data} | menu_list]}
        end)

      menu, child ->
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

  @doc """
  Teminates session the gateway session id.
  ```elixir
    iex> ExUssd.end_session(session_id: "sn1")
  ```
  """
  @spec end_session(keyword()) :: no_return()
  def end_session(session_id: session_id) do
    ExUssd.Registry.stop(session_id)
  end

  @doc """
  `ExUssd.goto/1` is called when the gateway provider calls the callback URL.
  Returns
  menu_string: to be used as gateway response string.
  should_close: indicates if the gateway should close the session.
  """
  @spec goto(map() | keyword()) :: {:ok, %{menu_string: String.t(), should_close: boolean()}}
  def goto(opts)

  def goto(fields) when is_list(fields),
    do: goto(Enum.into(fields, %{}))

  def goto(%{
        payload: %{text: _, session_id: session, service_code: _} = payload,
        menu: menu
      }) do
    payload
    |> ExUssd.Route.get_route()
    |> ExUssd.Navigation.navigate(menu, payload)
    |> ExUssd.Display.to_string(ExUssd.Registry.fetch_state(session), Keyword.new(payload))
  end

  def goto(%{
        payload: %{"text" => _, "session_id" => _, "service_code" => _} = payload,
        menu: menu
      }) do
    goto(%{payload: Utils.format(payload), menu: menu})
  end

  def goto(%{payload: %{"session_id" => _, "service_code" => _} = payload, menu: _}) do
    message = "'text' not found in payload #{inspect(payload)}"
    raise %ArgumentError{message: message}
  end

  def goto(%{payload: %{"text" => _, "service_code" => _} = payload, menu: _}) do
    message = "'session_id' not found in payload #{inspect(payload)}"
    raise %ArgumentError{message: message}
  end

  def goto(%{payload: %{"text" => _, "session_id" => _} = payload, menu: _}) do
    message = "'service_code' not found in payload #{inspect(payload)}"
    raise %ArgumentError{message: message}
  end

  def goto(%{payload: payload, menu: _}) do
    message = "'text', 'service_code', 'session_id',  not found in payload #{inspect(payload)}"

    raise %ArgumentError{message: message}
  end

  @doc """
  Returns the ExUssd struct for the given keyword list opts.
  """

  @spec new(String.t(), fun()) :: ExUssd.t()
  def new(name, fun) when is_function(fun, 2) and is_bitstring(name) do
    ExUssd.new(navigate: fun, name: name)
  end

  def new(name, fun) when is_function(fun, 2) do
    raise ArgumentError, "`name` must be a string, #{inspect(name)}"
  end

  def new(_name, fun) do
    raise ArgumentError, "expected a function with arity of 2, found #{inspect(fun)}"
  end

  @spec new(fun()) :: ExUssd.t()
  def new(fun) when is_function(fun, 2) do
    ExUssd.new(navigate: fun, name: "")
  end

  @spec new(keyword()) :: ExUssd.t()
  def new(opts) do
    fun = fn opts ->
      if Keyword.keyword?(opts) do
        {_, opts} =
          Keyword.get_and_update(
            opts,
            :name,
            &{&1, Utils.truncate(&1, length: 140, omission: "...")}
          )

        struct!(
          ExUssd,
          Keyword.take(opts, [:data, :resolve, :name, :orientation, :is_zero_based])
        )
      end
    end

    with {:error, message} <- apply(fun, [opts]) |> validate_new(opts) do
      raise %ArgumentError{message: message}
    end
  end

  @doc """
  Sets the allowed fields on ExUssd struct.
  """

  @spec set(ExUssd.t(), keyword()) :: ExUssd.t()
  def set(menu, opts)

  def set(%ExUssd{} = menu, nav: %ExUssd.Nav{type: type} = nav)
      when type in [:home, :next, :back] do
    case Enum.find_index(menu.nav, fn nav -> nav.type == type end) do
      nil ->
        menu

      index ->
        Map.put(menu, :nav, List.update_at(menu.nav, index, fn _ -> nav end))
    end
  end

  def set(%ExUssd{resolve: existing_resolve} = menu, resolve: resolve)
      when not is_nil(existing_resolve) do
    %{menu | navigate: resolve}
  end

  def set(%ExUssd{resolve: nil} = menu, resolve: resolve)
      when is_function(resolve) or is_atom(resolve) do
    %{menu | resolve: resolve}
  end

  def set(%ExUssd{resolve: nil}, resolve: resolve) do
    raise %ArgumentError{
      message: "resolve should be a function or a resolver module, found #{inspect(resolve)}"
    }
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
  Returns Menu string for the given ExUssd struct.
  """

  @spec to_string(ExUssd.t(), keyword()) ::
          {:ok, %{:menu_string => binary(), :should_close => boolean()}} | {:error, String.t()}
  def to_string(%ExUssd{} = menu, opts) do
    case Utils.get_menu(menu, opts) do
      %ExUssd{} = menu ->
        Display.to_string(menu, ExUssd.Route.get_route(%{text: "*test#", service_code: "*test#"}))

      _ ->
        {:error, "Couldn't convert #{inspect(menu)} to_string"}
    end
  end

  @spec to_string(ExUssd.t(), atom, keyword()) ::
          {:ok, %{:menu_string => binary(), :should_close => boolean()}} | {:error, String.t()}
  def to_string(%ExUssd{} = menu, atom, opts) do
    if Keyword.get(opts, :simulate) do
      raise %ArgumentError{message: "simulate is not supported, Use ExUssd.to_string/2"}
    end

    case Utils.get_menu(menu, atom, opts) do
      %ExUssd{} = menu ->
        Display.to_string(menu, ExUssd.Route.get_route(%{text: "*test#", service_code: "*test#"}))

      _ ->
        {:error, "Couldn't convert to_string for callback #{inspect(atom)}"}
    end
  end

  @spec to_string!(ExUssd.t(), keyword()) :: String.t()
  def to_string!(%ExUssd{} = menu, opts) do
    case to_string(menu, opts) do
      {:ok, %{menu_string: menu_string}} -> menu_string
      {:error, error} -> raise ArgumentError, error
    end
  end

  @spec to_string!(ExUssd.t(), atom, keyword()) :: String.t()
  def to_string!(%ExUssd{} = menu, atom, opts) do
    case to_string(menu, atom, opts) do
      {:ok, %{menu_string: menu_string}} -> menu_string
      {:error, error} -> raise ArgumentError, error
    end
  end

  @spec validate_new(nil | ExUssd.t(), any()) :: ExUssd.t() | {:error, String.t()}
  defp validate_new(menu, opts)

  defp validate_new(nil, opts) do
    {:error,
     "Expected a keyword list opts or callback function with arity of 2, found #{inspect(opts)}"}
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
end
