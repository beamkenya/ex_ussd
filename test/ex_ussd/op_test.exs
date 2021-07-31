defmodule ExUssd.OpTest do
  @moduledoc false
  use ExUnit.Case

  setup do
    resolve = fn menu, _api_parameters, _metadata -> menu |> ExUssd.set(title: "Welcome") end

    menu = ExUssd.new(name: Faker.Company.name(), resolve: resolve)

    %{resolve: resolve, menu: menu}
  end

  describe "new/1" do
    test "successfully sets the hander field", %{resolve: resolve} do
      name = Faker.Company.name()
      options = [name: name, resolve: resolve]
      assert %ExUssd{name: ^name, resolve: ^resolve} = ExUssd.new(options)
    end

    test "raise ArgumentError if the name is not provided", %{resolve: resolve} do
      assert_raise ArgumentError, "Expected :name in opts, found [:resolve]", fn ->
        ExUssd.new(resolve: resolve)
      end
    end

    test "raise ArgumentError if the orientation is unknown", %{resolve: resolve} do
      name = Faker.Company.name()
      orientation = :top

      assert_raise ArgumentError, "Unknown orientation value, #{inspect(orientation)}", fn ->
        ExUssd.new(orientation: orientation, name: name, resolve: resolve)
      end
    end

    test "raise ArgumentError if opt is not a key wordlist", %{resolve: resolve} do
      opts = %{resolve: resolve}

      assert_raise ArgumentError, "Expected a keyword list opts found #{inspect(opts)}", fn ->
        ExUssd.new(opts)
      end
    end
  end

  describe "set/2" do
    test "successfully sets the title and should_close field", %{menu: menu} do
      title = Faker.Lorem.sentence(4..10)

      assert %ExUssd{title: ^title, should_close: true} =
               ExUssd.set(menu, title: title, should_close: true)
    end

    test "raise ArgumentError if opts value is not part of the allowed_fields", %{menu: menu} do
      assert_raise ArgumentError,
                   "Expected field in allowable fields [:error, :title, :next, :previous, :should_close, :split, :delimiter, :default_error, :show_navigation, :data] found [:close]",
                   fn -> ExUssd.set(menu, close: true) end
    end
  end

  describe "add/2" do
    test "vertical: successfully add menu to menu list", %{menu: menu, resolve: resolve} do
      menu1 = ExUssd.new(name: Faker.Company.name(), resolve: resolve)
      menu2 = ExUssd.new(name: Faker.Company.name(), resolve: resolve)
      assert %ExUssd{menu_list: [^menu2, ^menu1]} = menu |> ExUssd.add(menu1) |> ExUssd.add(menu2)
    end

    test "horizontal: successfully add menu to menu list", %{resolve: resolve} do
      home = ExUssd.new(name: Faker.Company.name(), resolve: resolve, orientation: :horizontal)
      menu1 = ExUssd.new(name: Faker.Company.name(), resolve: resolve)
      menu2 = ExUssd.new(name: Faker.Company.name(), resolve: resolve)
      assert %ExUssd{menu_list: [^menu2, ^menu1]} = home |> ExUssd.add(menu1) |> ExUssd.add(menu2)
    end

    test "vertical: successfully add menus to menu list", %{resolve: resolve} do
      home = ExUssd.new(name: Faker.Company.name(), resolve: resolve, orientation: :vertical)
      menu1 = ExUssd.new(name: Faker.Company.name(), resolve: resolve)
      menu2 = ExUssd.new(name: Faker.Company.name(), resolve: resolve)

      assert %ExUssd{menu_list: [^menu2, ^menu1]} =
               home |> ExUssd.add([menu1, menu2], resolve: resolve)
    end

    test "horizontal: successfully add menus to menu list", %{resolve: resolve} do
      home = ExUssd.new(name: Faker.Company.name(), resolve: resolve, orientation: :horizontal)
      menu1 = ExUssd.new(name: Faker.Company.name())
      menu2 = ExUssd.new(name: Faker.Company.name())

      assert %ExUssd{menu_list: [^menu2, ^menu1]} = home |> ExUssd.add([menu1, menu2])
    end
  end
end
