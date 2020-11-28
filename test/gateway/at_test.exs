defmodule ExUssd.Gateway.AfricasTalkingTest do
  @moduledoc false

  use ExUnit.Case, async: true
  alias ExUssd.State.Registry

  setup do
    defmodule ProductAHandler do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu |> Map.put(:title, "selected product a")
      end
    end

    defmodule ProductBHandler do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu |> Map.put(:title, "selected product b")
      end
    end

    defmodule ProductCHandler do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu
        |> Map.put(:should_close, true)
        |> Map.put(:title, "selected product c")
      end
    end

    defmodule MyHomeHandler do
      @behaviour ExUssd.Handler
      def handle_menu(menu, _api_parameters) do
        menu
        |> Map.put(:title, "Welcome")
        |> Map.put(:split, 2)
        |> Map.put(
          :menu_list,
          [
            ExUssd.Menu.render(name: "Product A", handler: ProductAHandler),
            ExUssd.Menu.render(name: "Product B", handler: ProductBHandler),
            ExUssd.Menu.render(name: "Product C", handler: ProductCHandler)
          ]
        )
      end
    end
    menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)
    %{
      menu: menu
    }
  end

  # test "should close menu", %{menu: menu} do
  #   response = AfricasTalking.goto(
  #     internal_routing: %{text: "*544*3#", session_id: "session_2002", service_code: "*544#"},
  #     menu: menu,
  #     api_parameters: %{"text" => "" }
  #   )
  #   Process.sleep(5000)
  #   assert "" = response
  # end

  describe "test process text when text is blank " do
    internal_routing = %{text: "", session_id: "session_101", service_code: "*544#"}
    Registry.start(internal_routing.session_id)
    assert "" ==  AfricasTalking.process_text(internal_routing)
  end

  describe "test process text when text is *544*1# " do
    internal_routing = %{text: "*544*1#", session_id: "session_101", service_code: "*544#"}
    Registry.start(internal_routing.session_id)
    assert "*544*1" ==  AfricasTalking.process_text(internal_routing)
  end

  describe "test process text when text is 1" do
    internal_routing = %{text: "1", session_id: "session_101", service_code: "*544#"}
    Registry.start(internal_routing.session_id)
    assert "*544*1" ==  AfricasTalking.process_text(internal_routing)
  end

  test "test process text when text is *544# with state", %{menu: menu} do
    internal_routing = %{text: "*544#", session_id: "session_102", service_code: "*544#"}
    Registry.start(internal_routing.session_id)
    Registry.set_current_menu(internal_routing.session_id, menu)

    assert "" ==  AfricasTalking.process_text(internal_routing)
  end

  test "test process text when text is *544*1# with state", %{menu: menu} do
    internal_routing = %{text: "*544*1#", session_id: "session_102", service_code: "*544#"}
    Registry.start(internal_routing.session_id)
    Registry.set_current_menu(internal_routing.session_id, menu)

    assert "*544*1" ==  AfricasTalking.process_text(internal_routing)
  end

  test "test process text when text is 1 with state", %{menu: menu} do
    internal_routing = %{text: "1", session_id: "session_102", service_code: "*544#"}
    Registry.start(internal_routing.session_id)
    Registry.set_current_menu(internal_routing.session_id, menu)

    assert "1" ==  AfricasTalking.process_text(internal_routing)
  end

  test "test process text when text is 1*2 with state", %{menu: menu} do
    internal_routing = %{text: "1*2", session_id: "session_102", service_code: "*544#"}
    Registry.start(internal_routing.session_id)
    Registry.set_current_menu(internal_routing.session_id, menu)

    assert "2" ==  AfricasTalking.process_text(internal_routing)
  end

  test "test CON output", %{menu: menu} do
    internal_routing = %{session_id: "session_103"}
    %{display: menu_string, menu: current_menu} = ExUssd.Utils.navigate("", menu, "session_003")

    assert {:ok, "CON Welcome\n1:Product A\n2:Product B\n98:MORE"} ==  AfricasTalking.output(internal_routing, current_menu, menu_string)
  end

  test "test END output", %{menu: menu} do
    internal_routing = %{session_id: "session_103"}
    ExUssd.Utils.navigate("", menu, "session_003")
    %{display: menu_string, menu: current_menu} = ExUssd.Utils.navigate("3", menu, "session_003")

    assert {:ok, "END selected product c"} ==  AfricasTalking.output(internal_routing, current_menu, menu_string)
  end

  describe "test menu get menu" do
    defmodule MyHomeHandler do
      @behaviour ExUssd.Handler
     def handle_menu(menu, _api_parameters) do
        menu |> Map.put(:title, "Welcome")
      end
    end

    menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)
    session = "session_10004"
    AfricasTalking.goto(
      internal_routing: %{text: "", session_id: session, service_code: "*544#"},
      menu: menu,
      api_parameters: %{"text" => "" }
    )
    response_menu = ExUssd.State.Registry.get_menu(session)
    get_menu = AfricasTalking.get_menu(session_id: session)
    assert response_menu == get_menu
  end
end
