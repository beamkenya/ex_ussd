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

      iex> ExUssd.goto(
      ...>  internal_routing: %{text: "", session_id: "session_01", service_code: "*544#"},
      ...>  menu: ExUssd.Menu.render(
      ...>    name: "Home",
      ...>    handler: fn menu, _api_parameters, _should_handle ->
      ...>      menu |> Map.put(:title, "Home Page: Welcome")
      ...>    end
      ...>  ),
      ...>  api_parameters: %{
      ...>      "sessionId" => "session_01",
      ...>      "phoneNumber" => "254722000000",
      ...>      "networkCode" => "Safaricom",
      ...>      "serviceCode" => "*544#",
      ...>      "text" => ""
      ...>    }
      ...>  )
      {:ok, "CON Home Page: Welcome"}
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
  This a helper function that helps simulate ussd call
  ## Example
      iex> ExUssd.simulate(menu: ExUssd.Menu.render(
      ...>  name: "Home",
      ...>  handler: fn menu, _api_parameters, _should_handle ->
      ...>    menu
      ...>    |> Map.put(:title, "Welcome")
      ...>  end
      ...>),
      ...> text: "")
      {:ok, "Welcome"}
  """
  def simulate(menu: menu, text: text), do: Utils.simulate(menu: menu, text: text)
end
