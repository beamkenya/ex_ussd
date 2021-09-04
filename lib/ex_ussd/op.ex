defmodule ExUssd.Op do
  @moduledoc """
  Contains all ExUssd Public API functions
  """
  alias ExUssd.{Display, Executer, Route, Utils}

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
    :name
  ]

  @doc """
  Returns Menu string

  ## Example
    iex> menu = ExUssd.new(name: "home", resolve: fn menu, _payload -> menu |> ExUssd.set(title: "Welcome") end)
    
    iex> ExUssd.to_string(menu, [])
    {:ok, %{menu_string: "Welcome", should_close: false}}

    iex> ExUssd.to_string(menu, :ussd_init, [])
    {:ok, %{menu_string: "Welcome", should_close: false}}

    iex> menu = ExUssd.new(name: "home", resolve: HomeResolver)

    iex> ExUssd.to_string(menu, :ussd_init, [])
    {:ok, %{menu_string: "Enter your PIN", should_close: false}}

    iex> ExUssd.to_string(menu, :ussd_callback, [payload: %{text: "1"}, init_text: "1"])
    {:ok, %{menu_string: "Invalid Choice\nEnter your PIN", should_close: false}}

    iex> ExUssd.to_string(menu, :ussd_callback, [payload: %{text: "5555"}, init_text: "1"])
    {:ok, %{menu_string: "You have Entered the Secret Number, 5555", should_close: true}}

  """

  @spec to_string(ExUssd.t(), keyword()) ::
          {:ok, %{menu_string: String.t(), should_close: boolean()}}
  def to_string(%ExUssd{} = menu, opts), do: to_string(menu, :ussd_init, opts)

  @spec to_string(ExUssd.t(), :ussd_init, keyword()) ::
          {:ok, %{menu_string: String.t(), should_close: boolean()}}
  def to_string(%ExUssd{} = menu, :ussd_init, opts) do
    payload = Keyword.get(opts, :payload, %{text: "set_opts_payload_text"})

    fun = fn
      menu, payload ->
        menu
        |> Executer.execute_navigate(payload)
        |> Executer.execute_init_callback!(payload)
        |> Display.to_string(Route.get_route(%{text: "*544#", service_code: "*544#"}))
    end

    apply(fun, [menu, payload])
  end

  @spec to_string(ExUssd.t(), :ussd_callback, keyword()) ::
          {:ok, %{menu_string: String.t(), should_close: boolean()}}
  def to_string(%ExUssd{default_error: error} = menu, :ussd_callback, opts) do
    payload = Keyword.get(opts, :payload)

    fun = fn
      _menu, opts, nil ->
        raise ArgumentError, "`:payload` not found, #{inspect(Keyword.new(opts))}"

      menu, %{init_text: init_text}, %{text: _} = payload ->
        init_payload = Map.put(payload, :text, init_text)

        init_menu =
          menu
          |> Executer.execute_navigate(init_payload)
          |> Executer.execute_init_callback!(init_payload)

        callback_menu =
          with nil <- Executer.execute_callback!(init_menu, payload, state: false) do
            %{init_menu | error: error}
          end

        Display.to_string(callback_menu, Route.get_route(%{text: "*544#", service_code: "*544#"}))

      _menu, opts, %{text: _} ->
        raise ArgumentError, "opts missing `:init_text`, #{inspect(Keyword.new(opts))}"

      _menu, _, payload ->
        raise ArgumentError, "payload missing `:text`, #{inspect(payload)}"
    end

    apply(fun, [menu, Map.new(opts), payload])
  end

  @spec to_string(ExUssd.t(), :ussd_after_callback, keyword()) ::
          {:ok, %{menu_string: String.t(), should_close: boolean()}}
  def to_string(%ExUssd{default_error: error} = menu, :ussd_after_callback, opts) do
    payload = Keyword.get(opts, :payload)

    fun = fn
      _menu, opts, nil ->
        raise ArgumentError, "`:payload` not found, #{inspect(Keyword.new(opts))}"

      menu, %{init_text: init_text, callback_text: callback_text}, %{text: _} = payload ->
        init_payload = Map.put(payload, :text, init_text)
        callback_payload = Map.put(payload, :text, callback_text)

        init_menu =
          menu
          |> Executer.execute_navigate(init_payload)
          |> Executer.execute_init_callback!(init_payload)

        callback_menu =
          with nil <- Executer.execute_callback!(init_menu, callback_payload, state: false) do
            %{init_menu | error: error}
          end

        after_callback_menu =
          with nil <- Executer.execute_after_callback!(callback_menu, payload, state: false) do
            callback_menu
          end

        Display.to_string(
          after_callback_menu,
          Route.get_route(%{text: "*544#", service_code: "*544#"})
        )

      _menu, %{callback_text: _} = opts, %{text: _} ->
        raise ArgumentError, "opts missing `:init_text`, #{inspect(Keyword.new(opts))}"

      _menu, %{init_text: _} = opts, %{text: _} ->
        raise ArgumentError, "opts missing `:callback_text`, #{inspect(Keyword.new(opts))}"

      _menu, _, payload ->
        raise ArgumentError, "payload missing `:text`, #{inspect(payload)}"
    end

    apply(fun, [menu, Map.new(opts), payload])
  end

  @doc """
  Returns the ExUssd struct for the given keyword list opts.

  ## Parameters
   - `opts` — keyword lists, must include name field

  ## Example

    iex> ExUssd.new(orientation: :vertical, name: "home", resolve: MyHomeResolver)
    iex> ExUssd.new(orientation: :horizontal, name: "home", resolve: fn menu, _payload -> menu |> ExUssd.set(title: "Welcome") end)

    iex> ExUssd.new(fn menu, payload ->
      if is_registered?(phone_number: payload[:phone_number]) do
        menu
        |> ExUssd.set(name: "home")
        |> ExUssd.set(resolve: HomeResolver)
      else
        menu
        |> ExUssd.set(name: "guest")
        |> ExUssd.set(resolve: GuestResolver)
      end
    end)
  """

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

        struct!(ExUssd, Keyword.take(opts, [:data, :resolve, :name, :orientation, :navigate]))
      end
    end

    with {:error, message} <- apply(fun, [opts]) |> validate_new(opts) do
      raise %ArgumentError{message: message}
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

  @doc """
  Sets the allowed fields on ExUssd struct.

  ## Parameters
   - `:menu` — ExUssd Menu
   - `:opts` — Keyword list. Keys should be in the @allowed_fields

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
    :name
  ]

  ## Example
    iex> menu = ExUssd.new(name: "Home", resolve: &HomeResolver.welcome_menu/2)
    iex> menu |> ExUssd.set(title: "Welcome", data: %{a: 1}, should_close: true)
    iex> menu |> ExUssd.set(nav: ExUssd.Nav.new(type: :back, name: "BACK", match: "*"))
    iex> menu |> ExUssd.set(nav: [ExUssd.Nav.new(type: :back, name: "BACK", match: "*")])
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
  Add menu to ExUssd menu list.

  ## Parameters
    - `menu` — ExUssd Menu
    - `menu` — ExUssd or List of ExUssd
    - `opts` — Keyword list

  ## Example
    iex> menu = ExUssd.new(name: "Home", resolve: MyHomeResolver)
    iex> ExUssd.add(menu, ExUssd.new(name: "Product A", resolve: ProductResolver)))

  Add menus to to ExUssd menu list.
  Note: The menus with `orientation: :vertical` share one resolver

  ## Example
    iex> menu = ExUssd.new(orientation: :vertical, name: "Home", resolve: MyHomeResolver)
    iex> menu |> ExUssd.add([ExUssd.new(name: "Nairobi", data: %{city: "Nairobi", code: 47})], resolve: &CountyResolver.city_menu/2))
  """
  @spec add(ExUssd.t(), ExUssd.t() | [ExUssd.t()], keyword()) :: ExUssd.t()
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

  @doc """
  Teminates session the gateway session id.
  """
  @spec end_session(keyword()) :: no_return()
  def end_session(session_id: session_id) do
    ExUssd.Registry.stop(session_id)
  end

  @doc """
  Returns
  menu_string: to be used as gateway response string.
  should_close: indicates if the gateway should close the session.

  ## Parameters
   - `opts` — keyword list / map

  ## Example
  iex> case ExUssd.goto(menu: menu, payload: payload) do
    {:ok, %{menu_string: menu_string, should_close: false}} ->
      "CON " <> menu_string

    {:ok, %{menu_string: menu_string, should_close: true}} ->
      # End Session
      ExUssd.end_session(session_id: session_id)

      "END " <> menu_string
    end
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
end
