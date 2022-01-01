defmodule ExUssd.ExecuterTest do
  @moduledoc false
  use ExUnit.Case
  alias ExUssd.Executer

  describe "execute/3" do
    test "successfully executes anonymous resolve fn" do
      menu =
        ExUssd.new(
          name: Faker.Company.name(),
          resolve: fn menu, _payload -> {:ok, ExUssd.set(menu, title: "Welcome")} end
        )

      title = "Welcome"
      assert {:ok, %ExUssd{title: ^title}} = Executer.execute_init_callback(menu, Map.new())
    end

    test "raise BadArityError if resolve function does not take arity of 2" do
      menu =
        ExUssd.new(
          name: Faker.Company.name(),
          resolve: fn menu, _payload, _metadata -> {:ok, ExUssd.set(menu, title: "Welcome")} end
        )

      assert_raise BadArityError, fn -> Executer.execute_init_callback(menu, Map.new()) end
    end
  end
end
