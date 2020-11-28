defmodule ExUssd.Gateway.InfobipTest do
  @moduledoc false

  use ExUnit.Case, async: true

  describe "test end session" do
    defmodule MyHomeHandler do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu |> Map.put(:title, "Welcome")
      end
    end

    session = "session_10002"
    assert {:error, :not_found} = Infobip.end_session(session_id: session)
  end

  describe "test menu get menu" do
    defmodule MyHomeHandler do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu |> Map.put(:title, "Welcome")
      end
    end

    menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)
    session = "session_10003"

    Infobip.goto(
      internal_routing: %{text: "", session_id: session, service_code: "*544#"},
      menu: menu,
      api_parameters: %{"text" => ""}
    )

    response_menu = ExUssd.State.Registry.get_menu(session)
    get_menu = Infobip.get_menu(session_id: session)
    assert response_menu == get_menu
  end
end
