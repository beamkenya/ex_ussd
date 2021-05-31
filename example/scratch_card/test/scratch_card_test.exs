defmodule ScratchCardTest do
  use ExUnit.Case
  doctest ScratchCard

  test "greets the world" do
    assert ScratchCard.hello() == :world
  end
end
