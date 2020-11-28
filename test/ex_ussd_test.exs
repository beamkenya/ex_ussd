defmodule ExUssdTest do
  use ExUnit.Case
  doctest ExUssd
  doctest AfricasTalking
  doctest Infobip
  doctest ExUssd.Utils

  describe "test menu get menu" do
    defmodule MyHomeHandler do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu |> Map.put(:title, "Welcome")
      end
    end

    menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)
    session = "session_10001"
    %{menu: response_menu} = ExUssd.Utils.navigate("", menu, session)
    get_menu = ExUssd.get_menu(session_id: session)
    assert response_menu == get_menu
  end
end
