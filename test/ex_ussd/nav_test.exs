defmodule ExUssd.NavTest do
  @moduledoc false
  use ExUnit.Case

  describe "to_string/3" do
    test "successfully converts nav type to string" do
      next = ExUssd.Nav.new(type: :next, name: "MORE", match: "98")
      assert "MORE:98" == ExUssd.Nav.to_string(next)
    end

    test "successfully pad to left" do
      next = ExUssd.Nav.new(type: :next, name: "MORE", match: "98", left: 1)
      assert " MORE:98" == ExUssd.Nav.to_string(next)
    end

    test "successfully pad to right" do
      next = ExUssd.Nav.new(type: :next, name: "MORE", match: "98", right: 1)
      assert "MORE:98 " == ExUssd.Nav.to_string(next)
    end

    test "successfully pad to top" do
      next = ExUssd.Nav.new(type: :next, name: "MORE", match: "98", top: 1)

      assert "\nMORE:98" == ExUssd.Nav.to_string(next)
    end

    test "successfully pad to down" do
      next =
        ExUssd.Nav.new(type: :next, name: "MORE", match: "98", down: 1, orientation: :vertical)

      assert "MORE:98\n" == ExUssd.Nav.to_string(next)
    end

    test "successfully hides nav" do
      next = ExUssd.Nav.new(type: :next, name: "MORE", match: "98", show: false)
      assert "" == ExUssd.Nav.to_string(next)
    end
  end
end
