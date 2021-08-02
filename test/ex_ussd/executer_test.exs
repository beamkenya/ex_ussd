defmodule ExUssd.ExecuterTest do
  @moduledoc false
  use ExUnit.Case
  alias ExUssd.Executer

  describe "execute/3" do
    test "successfully executes anonymous resolve fn" do
      menu =
        ExUssd.new(
          name: Faker.Company.name(),
          resolve: fn menu, _api_parameters -> menu |> ExUssd.set(title: "Welcome") end
        )

      title = "Welcome"
      assert {:ok, %ExUssd{title: ^title}} = Executer.execute(menu, Map.new())
    end

    test "raise BadArityError if resolve function does not take arity of 2" do
      menu =
        ExUssd.new(
          name: Faker.Company.name(),
          resolve: fn menu, _api_parameters, _metadata -> menu |> ExUssd.set(title: "Welcome") end
        )

      assert_raise BadArityError, fn -> Executer.execute(menu, Map.new()) end
    end
  end
end
