defmodule ExUssd.ExecuterTest do
  @moduledoc false
  use ExUnit.Case
  alias ExUssd.Executer

  setup do
    resolve = fn menu, _api_parameters, _metadata -> menu |> ExUssd.set(title: "Welcome") end

    menu = ExUssd.new(name: Faker.Company.name(), resolve: resolve)

    %{menu: menu}
  end

  describe "execute/3" do
    test "successfully executes anonymous resolve fn", %{menu: menu} do
      title = "Welcome"
      assert %ExUssd{title: ^title} = Executer.execute(menu, Map.new(), Map.new())
    end
  end
end
