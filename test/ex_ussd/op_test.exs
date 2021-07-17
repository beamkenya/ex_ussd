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

    %{handler: HomeHandler, name: "home"}
  end

  describe "new!/1" do
    test "successfully sets the hander field", %{name: name, handler: handler} do
      options = [name: name, handler: handler]
      assert %ExUssd{name: ^name, handler: ^handler} = ExUssd.new!(options)
    end
  end
end
