defmodule ExUssd.State.RegistryTest do
  @moduledoc false

  use ExUnit.Case, async: true
  alias ExUssd.State.Registry
  alias ExUssd.Routes

  setup do
    internal_routing = %{text: "1", session_id: "session_01", service_code: "*544#"}
    Registry.start(internal_routing.session_id)
  end

  test "add route path (level 1)" do
    route = Routes.get_route(%{text: "*544#", service_code: "*544#"})
    routes = Registry.add("session_01", route)
    assert [%{depth: 1, value: "555"}] == routes
  end

  test "get current route on level 1" do
    route = Routes.get_route(%{text: "*544#", service_code: "*544#"})
    Registry.add("session_01", route)
    assert [%{depth: 1, value: "555"}] == Registry.get("session_01")
  end

  test "increase depth on level 1" do
    route = Routes.get_route(%{text: "*544#", service_code: "*544#"})
    Registry.add("session_01", route)
    Registry.next("session_01")
    assert [%{depth: 2, value: "555"}] == Registry.get("session_01")
  end

  test "add route path (level 2)" do
    route = Routes.get_route(%{text: "*544*1#", service_code: "*544#"})
    Registry.add("session_01", route)
    assert [%{depth: 1, value: "1"}, %{depth: 1, value: "555"}] == Registry.get("session_01")
  end

  test "add route path (level 2) using text" do
    route1 = Routes.get_route(%{text: "*544#", service_code: "*544#"})
    route2 = Routes.get_route(%{text: "1", service_code: "*544#"})
    Registry.add("session_01", route1)
    Registry.add("session_01", route2)

    assert [%{depth: 1, value: "1"}, %{depth: 1, value: "555"}] == Registry.get("session_01")
  end

  test "increase depth on level 2" do
    route = Routes.get_route(%{text: "*544*1#", service_code: "*544#"})
    Registry.add("session_01", route)
    Registry.next("session_01")
    assert [%{depth: 2, value: "1"}, %{depth: 1, value: "555"}] == Registry.get("session_01")
  end

  test "go Back from level 2" do
    route = Routes.get_route(%{text: "*544*1#", service_code: "*544#"})
    Registry.add("session_01", route)
    Registry.previous("session_01")
    assert [%{depth: 1, value: "555"}] == Registry.get("session_01")
  end

  test "goback on increase depth on level 2" do
    route = Routes.get_route(%{text: "*544*1#", service_code: "*544#"})
    Registry.add("session_01", route)
    Registry.next("session_01")
    Registry.previous("session_01")
    assert [%{depth: 1, value: "1"}, %{depth: 1, value: "555"}] == Registry.get("session_01")
  end

  test "goback to level 1 from increase depth on level 2" do
    route = Routes.get_route(%{text: "*544*1#", service_code: "*544#"})
    Registry.add("session_01", route)
    Registry.next("session_01")
    Registry.previous("session_01")
    Registry.previous("session_01")
    assert [%{depth: 1, value: "555"}] == Registry.get("session_01")
  end

  test "goback on level 1" do
    route = Routes.get_route(%{text: "*544*1#", service_code: "*544#"})
    Registry.add("session_01", route)
    Registry.previous("session_01")
    assert [%{depth: 1, value: "555"}] == Registry.get("session_01")
  end
end
