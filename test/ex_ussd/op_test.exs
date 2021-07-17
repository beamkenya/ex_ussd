defmodule ExUssd.OpTest do
  use ExUnit.Case

  setup do
    defmodule HomeHandler do
      use ExUssd.Handler

      def ussd_init(menu, _api_parameters) do
        menu
        |> Map.put(:title, "welcome to USSD home")
      end
    end

    menu = ExUssd.new(name: "", handler: HomeHandler)

    %{handler: HomeHandler, menu: menu}
  end

  describe "new/1" do
    test "successfully sets the hander field", %{handler: handler} do
      name = Faker.Company.name()
      options = [name: name, handler: handler]
      assert %ExUssd{name: ^name, handler: ^handler} = ExUssd.new(options)
    end
  end

  describe "set/2" do
    test "successfully sets the title and should_close field", %{menu: menu} do
      title = Faker.Lorem.sentence(4..10)
      assert %ExUssd{title: ^title, should_close: true} = ExUssd.set(menu, title: title, should_close: true)
    end
  end
end
