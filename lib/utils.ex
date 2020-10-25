defmodule ExUssd.Utils do
  @doc false
  def call_menu_callback(
        %ExUssd.Menu{} = menu,
        %{} = api_parameters \\ %{},
        should_handle \\ false
      ) do
    menu.callback.(api_parameters, should_handle)
  end

  @doc """
  This a helper function that helps simulate ussd call
  ## Example
      iex> ExUssd.Utils.simulate(menu: ExUssd.Menu.render(
      ...>  name: "Home",
      ...>  handler: fn menu, _api_parameters, _should_handle ->
      ...>    menu
      ...>    |> Map.put(:title, "Welcome")
      ...>  end
      ...>),
      ...> text: "")
      {:ok, "Welcome"}
  """
  def simulate(menu: menu, text: text) do
    internal_routing = %{text: text, session_id: "session_01", service_code: "*544#"}

    api_parameters = %{
      "text" => internal_routing.text
    }

    route =
      ExUssd.Routes.get_route(%{
        text: internal_routing.text,
        service_code: internal_routing.service_code
      })

    %{display: menu_string} =
      EXUssd.Common.goto(
        internal_routing: internal_routing,
        menu: menu,
        api_parameters: api_parameters,
        route: route
      )

    {:ok, menu_string}
  end
end
