defmodule ExUssd.Utils do
  @doc false
  def call_menu_callback(
        %ExUssd.Menu{} = menu,
        %{} = api_parameters \\ %{}
      ) do
    menu.callback.(api_parameters)
  end

  @doc """
  This a helper function that helps simulate ussd call
  ## Example
      iex> defmodule MyHomeHandler do
      ...>  @behaviour ExUssd.Handler
      ...>  def handle_menu(menu, _api_parameters) do
      ...>      menu |> Map.put(:title, "Welcome")
      ...>  end
      ...> end
      iex> menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)
      iex> ExUssd.Utils.simulate(menu: menu, text: "")
      {:ok, %{menu_string: "Welcome", should_close: false}}
  """

  def simulate(menu: menu, text: text) do
    internal_routing = %{text: text, session_id: "session_01", service_code: "*544#"}

    %{display: menu_string, menu: %{should_close: should_close}} =
      navigate(text, menu, internal_routing.session_id)

    {:ok, %{menu_string: menu_string, should_close: should_close}}
  end

  @doc """
  This a helper function that helps simulate ussd call
  ## Example
      iex> defmodule MyHomeHandler do
      ...>  @behaviour ExUssd.Handler
      ...>  def handle_menu(menu, _api_parameters) do
      ...>      menu |> Map.put(:title, "Welcome")
      ...>  end
      ...> end
      iex> menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)
      iex> ExUssd.Utils.simulate(menu: menu, text: "", service_code: "*141#")
      {:ok, %{menu_string: "Welcome", should_close: false}}
  """

  def simulate(menu: menu, text: text, service_code: service_code) do
    internal_routing = %{text: text, session_id: "session_02", service_code: service_code}

    %{display: menu_string, menu: %{should_close: should_close}} =
      navigate(text, menu, internal_routing.session_id, internal_routing.service_code)

    {:ok, %{menu_string: menu_string, should_close: should_close}}
  end

  def navigate(text, menu, session_id \\ "session_03", service_code \\ "*544#") do
    internal_routing = %{text: text, session_id: session_id, service_code: service_code}

    api_parameters = %{"text" => internal_routing.text}

    route =
      ExUssd.Routes.get_route(%{
        text: internal_routing.text,
        service_code: internal_routing.service_code
      })

    EXUssd.Common.goto(
      internal_routing: internal_routing,
      menu: menu,
      api_parameters: api_parameters,
      route: route
    )
  end

  def to_int({value, ""}, menu, input_value) do
    %{
      next: %{input_match: next},
      previous: %{input_match: previous},
      home: %{input_match: home, enable: is_home_enable}
    } = menu

    text = Integer.to_string(value)

    case input_value == home do
      true ->
        case is_home_enable do
          true ->
            705_897_792_423_629_962_208_442_626_284

          _ ->
            value
        end

      _ ->
        case text do
          v when v == next ->
            605_356_150_351_840_375_921_999_017_933

          v when v == previous ->
            128_977_754_852_657_127_041_634_246_588

          _ ->
            value
        end
    end
  end

  def to_int(:error, _menu, _input_value), do: 999

  def to_int({_value, _}, _menu, _input_value), do: 999
end
