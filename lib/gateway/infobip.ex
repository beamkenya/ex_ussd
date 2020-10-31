defmodule Infobip do
  alias ExUssd.State.Registry
  alias ExUssd.Routes

  @behaviour ExUssd.Ussd

  @doc """
  Infobip

  ## Configuration
  Add below config to dev.exs / prod.exs files

  `config.exs`
    ```elixir
      config :ex_ussd :provider, Infobip
    ```
  ## Example

      iex> defmodule HomeHandler do
      ...>   @behaviour ExUssd.Handler
      ...>  def handle_menu(menu, _api_parameters, _should_handle) do
      ...>    menu |> Map.put(:title, "Welcome")
      ...>  end
      ...>end
      iex> menu = ExUssd.Menu.render(name: "Home", handler: HomeHandler)
      iex> Infobip.goto(
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
      {:ok,
        %{
          shouldClose: false,
          ussdMenu: "Welcome",
          responseExitCode: 200,
          responseMessage: ""
        }
      }
  """
  @impl true
  def goto(internal_routing: internal_routing, menu: menu, api_parameters: api_parameters) do
    route =
      Routes.get_route(%{text: internal_routing.text, service_code: internal_routing.service_code})

    %{menu: current_menu, display: menu_string} =
      EXUssd.Common.goto(
        internal_routing: internal_routing,
        menu: menu,
        api_parameters: api_parameters,
        route: route
      )

    {:ok,
     %{
       shouldClose: current_menu.should_close,
       ussdMenu: menu_string,
       responseExitCode: 200,
       responseMessage: ""
     }}
  end

  @impl true
  def end_session(session_id: session_id) do
    Registry.stop(session_id)
  end

  @impl true
  def get_menu(session_id: session_id) do
    ExUssd.State.Registry.get_menu(session_id)
  end
end
