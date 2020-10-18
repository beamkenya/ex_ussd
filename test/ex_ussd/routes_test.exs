defmodule ExUssd.RoutesTest do
  @moduledoc false
  use ExUnit.Case, async: true

  doctest ExUssd.Routes

  alias ExUssd.Routes

  describe "initial route" do
    route = Routes.get_route(%{text: "*544#", service_code: "*544#"})
    assert [%{depth: 1, value: "555"}] == route
  end

  describe "nested path route" do
    route = ExUssd.Routes.get_route(%{text: "*544*2*3#", service_code: "*544#"})
    assert [%{depth: 1, value: "3"}, %{depth: 1, value: "2"}, %{depth: 1, value: "555"}] == route
  end

  describe "text to route" do
    route = Routes.get_route(%{text: "2", service_code: "*544#"})
    assert %{depth: 1, value: "2"} == route
  end
end
