defmodule AfricasTalking do
  alias ExUssd.Routes
  alias ExUssd.State.Registry

  @behaviour ExUssd.Ussd

  @doc """
  Africa's talking

  ## Configuration
  Add below config to dev.exs / prod.exs files

  `config.exs`
    ```elixir
      config :ex_ussd :provider, AfricasTalking
    ```
  ## Example

      iex> AfricasTalking.goto(
      ...>  internal_routing: %{text: "", session_id: "session_01", service_code: "*544#"},
      ...>  menu: ExUssd.Menu.render(
      ...>    name: "Home",
      ...>    handler: fn menu, _api_parameters, _should_handle ->
      ...>      menu |> Map.put(:title, "Home Page: Welcome")
      ...>    end
      ...>  ),
      ...>  api_parameters: %{
      ...>      sessionId: "session_01",
      ...>      phoneNumber: "254722000000",
      ...>      networkCode: "Safaricom",
      ...>      serviceCode: "*544#",
      ...>      text: "1"
      ...>    }
      ...>  )
      {:ok, "CON Home Page: Welcome"}
  """
  @impl true
  def goto(internal_routing: internal_routing, menu: menu, api_parameters: api_parameters) do
    text =
      case internal_routing.text |> String.split("*") do
        value when length(value) == 1 -> value |> hd
        value -> Enum.reverse(value) |> hd
      end

    route = Routes.get_route(%{text: text, service_code: internal_routing.service_code})

    %{menu: current_menu, display: menu_string} =
      EXUssd.Common.goto(
        internal_routing: internal_routing,
        menu: menu,
        api_parameters: api_parameters,
        route: route
      )

    %{should_close: should_close} = current_menu

    output =
      case should_close do
        false ->
          "CON " <> menu_string

        true ->
          Registry.stop(internal_routing.session_id)
          "END " <> menu_string
      end

    {:ok, output}
  end

  @doc """
  End session by ID
  ## Example
      iex> AfricasTalking.end_session(session_id: "session_01")
      {:error, :not_found}
  """
  @impl true
  def end_session(session_id: _session_id) do
    {:error, :not_found}
  end
end
