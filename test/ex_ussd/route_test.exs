defmodule ExUssd.RouteTest do
  @moduledoc false

  use ExUnit.Case

  describe "get_route/2" do
    test "get route when text is equivalent to service code" do
      assert %ExUssd.Route{mode: :parallel, route: [%{depth: 1, text: "555"}]} =
               ExUssd.Route.get_route(%{text: "*544#", service_code: "*544#"})
    end

    test "get route when text is contains service code" do
      assert %ExUssd.Route{
               mode: :parallel,
               route: [
                 %{depth: 1, text: "3"},
                 %{depth: 1, text: "2"},
                 %{depth: 1, text: "555"}
               ]
             } = ExUssd.Route.get_route(%{text: "*544*2*3#", service_code: "*544#"})
    end

    test "get route when text does not contains service code" do
      assert %ExUssd.Route{
               mode: :parallel,
               route: [
                 %{depth: 1, text: "3"},
                 %{depth: 1, text: "2"},
                 %{depth: 1, text: "555"}
               ]
             } = ExUssd.Route.get_route(%{text: "2*3#", service_code: "*544#"})
    end

    test "get route when text does not contains service code and session already exist" do
      assert ExUssd.Registry.start("session_01")

      assert %ExUssd.Route{
               mode: :serial,
               route: %{depth: 1, text: "2"}
             } =
               ExUssd.Route.get_route(%{
                 text: "3*2",
                 service_code: "*544#",
                 session_id: "session_01"
               })
    end
  end
end
