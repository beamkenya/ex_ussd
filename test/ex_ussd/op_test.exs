defmodule ExUssd.OpTest.Module do
  @moduledoc false
  def ussd_init(menu, _) do
    {:ok, ExUssd.set(menu, title: "Enter your PIN")}
  end

  def ussd_callback(menu, payload, _) do
    if payload.text == "5555" do
      {:ok,
       menu
       |> ExUssd.set(title: "You have Entered the Secret Number, 5555")
       |> ExUssd.set(should_close: true)}
    end
  end

  def simple(menu, _) do
    {:ok,
     menu
     |> ExUssd.set(title: "Welcome")
     |> ExUssd.add(
       ExUssd.new(
         name: "menu 1",
         resolve: &simple/2
       )
       |> ExUssd.set(split: 3)
     )
     |> ExUssd.add(
       ExUssd.new(
         name: "menu 2",
         resolve: fn menu, _ -> {:ok, ExUssd.set(menu, title: "menu 2")} end
       )
     )
     |> ExUssd.add(
       ExUssd.new(
         name: "menu 3",
         resolve: fn menu, _ -> {:ok, ExUssd.set(menu, title: "menu 3")} end
       )
     )
     |> ExUssd.add(
       ExUssd.new(
         name: "menu 4",
         resolve: fn menu, _ -> {:ok, ExUssd.set(menu, title: "menu 4")} end
       )
     )
     |> ExUssd.add(
       ExUssd.new(
         name: "menu 5",
         resolve: fn menu, _ -> {:ok, ExUssd.set(menu, title: "menu 5")} end
       )
     )}
  end
end

defmodule ExUssd.OpTest do
  @moduledoc false
  use ExUnit.Case

  setup do
    resolve = fn menu, _payload -> {:ok, ExUssd.set(menu, title: "Welcome")} end

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
      assert_raise ArgumentError, fn -> ExUssd.new(%{resolve: resolve}) end
    end
  end

  describe "set/2" do
    test "successfully sets the title and should_close field", %{menu: menu} do
      title = Faker.Lorem.sentence(4..10)

      assert %ExUssd{title: ^title, should_close: true} =
               ExUssd.set(menu, title: title, should_close: true)
    end

    test "raise ArgumentError if opts value is not part of the allowed_fields", %{menu: menu} do
      assert_raise ArgumentError, fn -> ExUssd.set(menu, close: true) end
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

  describe "goto/1 simple" do
    setup do
      %{
        menu: ExUssd.new(name: Faker.Company.name(), resolve: &ExUssd.OpTest.Module.simple/2),
        session: "#{System.unique_integer()}"
      }
    end

    test "successfully navigates to the first layer", %{menu: menu, session: session} do
      assert {:ok,
              %{
                menu_string: "Welcome\n1:menu 1\n2:menu 2\n3:menu 3\n4:menu 4\n5:menu 5",
                should_close: false
              }} ==
               ExUssd.goto(%{
                 payload: %{session_id: session, text: "", service_code: "*544#"},
                 menu: menu
               })
    end

    test "successfully navigates to the first menu option", %{menu: menu, session: session} do
      assert {:ok,
              %{
                menu_string: "Welcome\n1:menu 1\n2:menu 2\n3:menu 3\n00:HOME\nBACK:0 MORE:98",
                should_close: false
              }} ==
               ExUssd.goto(%{
                 payload: %{session_id: session, text: "1", service_code: "*544#"},
                 menu: ExUssd.set(menu, split: 3)
               })
    end

    test "successfully navigates to the nested menu", %{menu: menu, session: session} do
      assert {:ok,
              %{
                menu_string: "Welcome\n4:menu 4\n5:menu 5\n00:HOME\nBACK:0",
                should_close: false
              }} ==
               ExUssd.goto(%{
                 payload: %{session_id: session, text: "98", service_code: "*544#"},
                 menu: ExUssd.set(menu, split: 3)
               })
    end

    test "successfully navigates back the nested menu", %{menu: menu, session: session} do
      assert {:ok,
              %{
                menu_string: "Welcome\n1:menu 1\n2:menu 2\n3:menu 3\nMORE:98",
                should_close: false
              }} ==
               ExUssd.goto(%{
                 payload: %{session_id: session, text: "0", service_code: "*544#"},
                 menu: ExUssd.set(menu, split: 3)
               })
    end

    test "successfully navigates back to home menu", %{menu: menu, session: session} do
      assert {:ok,
              %{
                menu_string: "Welcome\n1:menu 1\n2:menu 2\n3:menu 3\n4:menu 4\n5:menu 5",
                should_close: false
              }} ==
               ExUssd.goto(%{
                 payload: %{session_id: session, text: "0", service_code: "*544#"},
                 menu: menu
               })
    end

    test "successfully navigates to the home menu", %{menu: menu, session: session} do
      assert {:ok,
              %{
                menu_string: "Welcome\n1:menu 1\n2:menu 2\n3:menu 3\n4:menu 4\n5:menu 5",
                should_close: false
              }} ==
               ExUssd.goto(%{
                 payload: %{session_id: session, text: "00", service_code: "*544#"},
                 menu: menu
               })
    end
  end

  describe "goto/1 zero base" do
    setup do
      %{
        menu:
          ExUssd.new(
            name: Faker.Company.name(),
            is_zero_based: true,
            resolve: &ExUssd.OpTest.Module.simple/2
          ),
        session: "#{System.unique_integer()}"
      }
    end

    test "successfully navigates to the first layer", %{menu: menu, session: session} do
      assert {:ok,
              %{
                menu_string: "Welcome\n0:menu 1\n1:menu 2\n2:menu 3\n3:menu 4\n4:menu 5",
                should_close: false
              }} ==
               ExUssd.goto(%{
                 payload: %{session_id: session, text: "", service_code: "*544#"},
                 menu: menu
               })
    end

    test "successfully navigates to the first menu option", %{menu: menu, session: session} do
      assert {:ok,
              %{
                menu_string: "Welcome\n1:menu 1\n2:menu 2\n3:menu 3\n00:HOME\nBACK:0 MORE:98",
                should_close: false
              }} ==
               ExUssd.goto(%{
                 payload: %{session_id: session, text: "0", service_code: "*544#"},
                 menu: ExUssd.set(menu, split: 3)
               })
    end

    test "successfully navigates to the second menu option", %{menu: menu, session: session} do
      assert {:ok,
              %{
                menu_string: "menu 2\n00:HOME\nBACK:0",
                should_close: false
              }} ==
               ExUssd.goto(%{
                 payload: %{session_id: session, text: "*544*1#", service_code: "*544#"},
                 menu: ExUssd.set(menu, split: 3)
               })
    end
  end

  describe "goto/1 with callback" do
    setup do
      %{
        menu: ExUssd.new(name: Faker.Company.name(), resolve: ExUssd.OpTest.Module),
        session: "#{System.unique_integer()}"
      }
    end

    test "successfully navigates to the first menu", %{menu: menu, session: session} do
      assert {:ok, %{menu_string: "Enter your PIN", should_close: false}} ==
               ExUssd.goto(%{
                 payload: %{session_id: session, text: "", service_code: "*444#"},
                 menu: menu
               })
    end

    test "successfully calls the 'ussd_callback/3' function", %{menu: menu, session: session} do
      assert {:ok, %{menu_string: "You have Entered the Secret Number, 5555", should_close: true}} ==
               ExUssd.goto(%{
                 payload: %{session_id: session, text: "5555", service_code: "*444#"},
                 menu: menu
               })
    end
  end

  describe "metadata" do
    defmodule PinResolver do
      use ExUssd

      def ussd_init(menu, _) do
        {:ok, ExUssd.set(menu, title: "Enter your PIN")}
      end

      def ussd_callback(menu, payload, %{attempt: %{count: count}}) do
        if payload.text == "5555" do
          {:ok, ExUssd.set(menu, resolve: &success_menu/2)}
        else
          {:error, "Wrong PIN, #{2 - count} attempt left"}
        end
      end

      def ussd_after_callback(%{error: true} = menu, _payload, %{attempt: %{count: 3}}) do
        {:ok,
         menu
         |> ExUssd.set(title: "Account is locked, Dial *234# to reset your account")
         |> ExUssd.set(should_close: true)}
      end

      def success_menu(menu, _) do
        {:ok,
         menu
         |> ExUssd.set(title: "You have Entered the Secret Number, 5555")
         |> ExUssd.set(should_close: true)}
      end
    end

    setup do
      %{
        menu: ExUssd.new(name: Faker.Company.name(), resolve: PinResolver),
        session: "#{System.unique_integer()}"
      }
    end

    test "successfully navigates to the first menu", %{menu: menu, session: session} do
      assert {:ok, %{menu_string: "Enter your PIN", should_close: false}} ==
               ExUssd.goto(%{
                 payload: %{session_id: session, text: "*444#", service_code: "*444#"},
                 menu: menu
               })
    end

    test "successfully render the first error message", %{menu: menu, session: session} do
      assert {:ok,
              %{menu_string: "Wrong PIN, 2 attempt left\nEnter your PIN", should_close: false}} ==
               ExUssd.goto(%{
                 payload: %{session_id: session, text: "2211", service_code: "*444#"},
                 menu: menu
               })
    end
  end
end
