defmodule ExUssd.Utils do
  @moduledoc false
  alias ExUssd.Executer

  @default_value 436_739_010_658_356_127_157_159_114_145
  @is_zero_based 741_463_257_579_241_461_489_157_167_458

  @spec to_int(term() | {integer(), String.t()}, ExUssd.t(), map(), String.t()) :: integer()
  def to_int(input, menu, _, input_value)

  def to_int({0, _}, %ExUssd{is_zero_based: is_zero_based}, _payload, _input_value)
      when is_zero_based,
      do: 0

  def to_int({0, _}, menu, payload, input_value),
    do: to_int({@default_value, ""}, menu, payload, input_value)

  def to_int(
        {value, ""},
        %ExUssd{split: split, nav: nav, menu_list: menu_list, orientation: orientation},
        %{session_id: session},
        input_value
      ) do
    %ExUssd.Nav{match: next, show: show_next} = Enum.find(nav, &(&1.type == :next))
    %ExUssd.Nav{match: home, show: show_home} = Enum.find(nav, &(&1.type == :home))
    %ExUssd.Nav{match: back, show: show_back} = Enum.find(nav, &(&1.type == :back))

    %{depth: depth} =
      session
      |> ExUssd.Registry.fetch_route()
      |> List.first()

    # 1 * 7
    position = depth * split

    element = Enum.at(menu_list, position)
    menu = Enum.at(menu_list, value - 1)

    case input_value do
      v
      when v == next and show_next and orientation == :horizontal and depth < length(menu_list) ->
        605_356_150_351_840_375_921_999_017_933

      v when v == next and show_next and orientation == :vertical and not is_nil(element) ->
        605_356_150_351_840_375_921_999_017_933

      v when v == back and show_back ->
        128_977_754_852_657_127_041_634_246_588

      v when v == home and show_home ->
        705_897_792_423_629_962_208_442_626_284

      _v when orientation == :horizontal and is_nil(menu) ->
        @default_value

      _ ->
        value
    end
  end

  def to_int(:error, _menu, _, _input_value), do: @default_value

  def to_int(_, _, _, _), do: @default_value

  @spec truncate(String.t(), keyword()) :: String.t()
  def truncate(text, options \\ []) do
    len = options[:length] || 30
    omi = options[:omission] || "..."

    cond do
      !String.valid?(text) ->
        text

      String.length(text) < len ->
        text

      true ->
        stop = len - String.length(omi)

        "#{String.slice(text, 0, stop)}#{omi}"
    end
  end

  @doc """
  Generates an unique id.
  """
  def new_id, do: "#{System.unique_integer()}"

  @spec format(map()) :: map()
  def format(payload) do
    Map.new(payload, fn {key, val} ->
      try do
        {String.to_existing_atom(key), val}
      rescue
        _e in ArgumentError ->
          {String.to_atom(key), val}
      end
    end)
  end

  @spec fetch_metadata(map()) :: map()
  def fetch_metadata(%{session_id: session, service_code: service_code, text: text}) do
    %{route: [%{attempt: attempt} | _] = routes} = ExUssd.Registry.fetch_state(session)

    routes_string =
      routes
      |> Enum.reverse()
      |> get_in([Access.all(), Access.key(:text)])
      |> tl()
      |> Enum.join("*")

    service_code = String.replace(service_code, "#", "")

    routes_string =
      if(String.equivalent?(routes_string, ""),
        do: IO.iodata_to_binary([service_code, "#"]),
        else: IO.iodata_to_binary([service_code, "*", routes_string, "#"])
      )

    invoked_at = DateTime.truncate(DateTime.utc_now(), :second)
    %{attempt: attempt, invoked_at: invoked_at, route: routes_string, text: text}
  end

  def get_menu(%ExUssd{} = menu, opts) do
    payload = Keyword.get(opts, :payload, %{text: "set_init_text"})

    position =
      case Integer.parse(payload.text) do
        {position, ""} -> position
        _ -> 436_739_010_658_356_127_157_159_114_145
      end

    fun = fn
      %{simulate: true, position: position} ->
        %{error: error, menu_list: menu_list} =
          current_menu = get_menu(menu, :ussd_callback, opts)

        if error do
          case Enum.at(Enum.reverse(menu_list), position - 1) do
            nil ->
              get_menu(%{menu | error: true}, :ussd_after_callback, opts)

            %ExUssd{} = next_menu ->
              get_menu(next_menu, :ussd_init, opts)
          end
        else
          current_menu
        end

      _ ->
        get_menu(menu, :ussd_init, opts)
    end

    apply(fun, [Map.new(Keyword.put(opts, :position, position))])
  end

  def get_menu(%ExUssd{} = menu, :ussd_init, opts) do
    init_data = Keyword.get(opts, :init_data)
    payload = Keyword.get(opts, :payload)

    fun = fn
      menu, payload ->
        menu
        |> Executer.execute_navigate(payload)
        |> Executer.execute_init_callback!(payload)
    end

    apply(fun, [%{menu | data: init_data}, payload])
  end

  def get_menu(%ExUssd{default_error: error} = menu, :ussd_callback, opts) do
    init_data = Keyword.get(opts, :init_data)
    init_text = Keyword.get(opts, :init_text, "set_init_text")

    payload = Keyword.get(opts, :payload)

    fun = fn
      _menu, opts, nil ->
        raise ArgumentError, "`:payload` not found, #{inspect(Keyword.new(opts))}"

      menu, _, %{text: _} = payload ->
        init_payload = Map.put(payload, :text, init_text)

        init_menu =
          menu
          |> Executer.execute_navigate(init_payload)
          |> Executer.execute_init_callback!(init_payload)

        with nil <- Executer.execute_callback!(init_menu, payload, state: false) do
          %{init_menu | error: error}
        end

      _menu, _, payload ->
        raise ArgumentError, "payload missing `:text`, #{inspect(payload)}"
    end

    apply(fun, [%{menu | data: init_data}, Map.new(opts), payload])
  end

  def get_menu(%ExUssd{default_error: error} = menu, :ussd_after_callback, opts) do
    init_data = Keyword.get(opts, :init_data)
    init_text = Keyword.get(opts, :init_text, "set_init_text")

    payload = Keyword.get(opts, :payload)

    fun = fn
      _menu, opts, nil ->
        raise ArgumentError, "`:payload` not found, #{inspect(Keyword.new(opts))}"

      menu, _, %{text: _} = payload ->
        init_payload = Map.put(payload, :text, init_text)

        init_menu =
          menu
          |> Executer.execute_navigate(init_payload)
          |> Executer.execute_init_callback!(init_payload)

        callback_menu =
          with nil <- Executer.execute_callback!(init_menu, payload, state: false) do
            %{init_menu | error: error}
          end

        with nil <- Executer.execute_after_callback!(callback_menu, payload, state: false) do
          callback_menu
        end

      _menu, _, payload ->
        raise ArgumentError, "payload missing `:text`, #{inspect(payload)}"
    end

    apply(fun, [%{menu | data: init_data}, Map.new(opts), payload])
  end

  def get_menu(_menu, _atom, _opts), do: nil
end
