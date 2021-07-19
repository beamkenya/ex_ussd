defmodule ExUssd.OpTest do
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

    test "new/1 throws an error if the name is not provided", %{resolve: resolve} do
      assert catch_throw(throw(ExUssd.new(resolve: resolve))) ==
               "Expected :name in opts, found [:resolve]"
    end

    test "new/1 throws an error if the orientation is unknown", %{resolve: resolve} do
      name = Faker.Company.name()
      orientation = :top

      assert catch_throw(
               throw(ExUssd.new(orientation: orientation, name: name, resolve: resolve))
             ) ==
               "Unknown orientation value, #{inspect(orientation)}"
    end

    test "new/1 throws an error if opt is not a key wordlist", %{resolve: resolve} do
      opts = %{resolve: resolve}

      assert catch_throw(throw(ExUssd.new(opts))) ==
               "Expected a keyword list opts found #{inspect(opts)}"
    end
  end

  describe "set/2" do
    test "successfully sets the title and should_close field", %{menu: menu} do
      title = Faker.Lorem.sentence(4..10)

      assert %ExUssd{title: ^title, should_close: true} =
               ExUssd.set(menu, title: title, should_close: true)
    end

    test "set/1 throws an error if opts value is not part of the allowed_fields", %{menu: menu} do
      assert catch_throw(throw(ExUssd.set(menu, close: true))) ==
               "Expected field in allowable fields [:error, :title, :next, :previous, :should_close, :split, :delimiter, :default_error, :show_navigation, :data] found [:close]"
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
               home
               |> ExUssd.add(menus: [menu1, menu2], resolve: resolve)
    end

    test "horizontal: successfully add menus to menu list", %{resolve: resolve} do
      home = ExUssd.new(name: Faker.Company.name(), resolve: resolve, orientation: :horizontal)
      menu1 = ExUssd.new(name: Faker.Company.name(), resolve: resolve)
      menu2 = ExUssd.new(name: Faker.Company.name(), resolve: resolve)

      assert %ExUssd{menu_list: [^menu2, ^menu1]} =
               home
               |> ExUssd.add(
                 menus: [menu1, menu2],
                 resolve: resolve
               )
    end
  end
end
