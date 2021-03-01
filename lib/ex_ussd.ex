alias ExUssd.Utils

defmodule ExUssd do
  @moduledoc """
    USSD interation
  """

  @provider Application.get_env(:ex_ussd, :gateway) || AfricasTalking

  @doc """
  Navigation

  ## Configuration
  Add below config to dev.exs / prod.exs files

  `config.exs`
    ```elixir
      config :ex_ussd :provider, AfricasTalking
    ```

  ## Example
      iex> defmodule MyHomeHandler do
      ...>   @behaviour ExUssd.Handler
      ...>  def handle_menu(menu, _api_parameters) do
      ...>    menu |> Map.put(:title, "Welcome")
      ...>  end
      ...>end
      iex> menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)
      iex> ExUssd.goto(
      ...>  internal_routing: %{text: "", session_id: "session_01", service_code: "*544#"},
      ...>  menu: menu,
      ...>  api_parameters: %{
      ...>      "sessionId" => "session_01",
      ...>      "phoneNumber" => "254722000000",
      ...>      "networkCode" => "Safaricom",
      ...>      "serviceCode" => "*544#",
      ...>      "text" => ""
      ...>    }
      ...>  )
      {:ok, "CON Welcome"}
  """
  @spec goto(
          internal_routing: ExUssd.Ussd.internal_routing(),
          menu: ExUssd.Ussd.menu(),
          api_parameters: ExUssd.Ussd.api_parameters()
        ) :: any()
  def goto(internal_routing: internal_routing, menu: menu, api_parameters: api_parameters),
    do:
      @provider.goto(
        internal_routing: internal_routing,
        menu: menu,
        api_parameters: api_parameters
      )

  @doc """
  ## Example
      iex> ExUssd.end_session(session_id: "session_01")
      {:error, :not_found}
  """
  def end_session(session_id: session_id), do: @provider.end_session(session_id: session_id)

  def get_menu(session_id: session_id), do: @provider.get_menu(session_id: session_id)

  @doc """
  Simulates USSD call - takes /2 params

  ## Parameters
  attrs: - a list containing
    - `menu` - USSD menu
    - `text` - USSD text value

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
  def simulate(menu: menu, text: text), do: Utils.simulate(menu: menu, text: text)

  @doc """
  Simulates USSD call - takes /3 params

  ## Parameters
  attrs: - a list containing
    - `menu` - USSD menu
    - `text` - USSD text value
    - `service_code` - USSD short code

  ## Example
      iex> defmodule MyHomeHandler do
      ...>  @behaviour ExUssd.Handler
      ...>  def handle_menu(menu, _api_parameters) do
      ...>      menu |> Map.put(:title, "Welcome")
      ...>  end
      ...> end
      iex> menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)
      iex> ExUssd.simulate(menu: menu, text: "", service_code: "*141#")
      {:ok, %{menu_string: "Welcome", should_close: false}}
  """
  def simulate(menu: menu, text: text, service_code: service_code),
    do: Utils.simulate(menu: menu, text: text, service_code: service_code)
end
