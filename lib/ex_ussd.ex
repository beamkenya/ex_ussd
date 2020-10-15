defmodule ExUssd do
  @moduledoc """
    USSD interation
  """

  @provider Application.get_env(:ex_ussd, :provider) || Infobip

  @doc """
  Navigation

  ## Configuration
  Add below config to dev.exs / prod.exs files

  `config.exs`
    ```elixir
      config :ex_ussd :provider, Infobip
    ```

  ## Example

      iex> ExUssd.goto(
      ...>  internal_routing: %{text: "1", session_id: "session_01", service_code: "*544#"},
      ...>  menu: ExUssd.Menu.render(
      ...>    name: "Home",
      ...>    handler: fn menu, _api_parameters ->
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
      {:ok, "Home Page: Welcome"}
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

  def end_session(session_id: session_id), do: @provider.end_session(session_id: session_id)
end
