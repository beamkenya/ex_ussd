defmodule HomeResolver do
    use ExUssd

    def product_a(menu, _payload), do: menu |> ExUssd.set(title: "selected product a")
    def product_b(menu, _payload), do: menu |> ExUssd.set(title: "selected product b")
    def product_c(menu, _payload), do: menu |> ExUssd.set(title: "selected product c")

    def account(%{data: %{account_type: :personal}} = menu, _payload) do
       menu 
       |> ExUssd.set(name: "personal Account")
       |> ExUssd.set(resolve: &personal_account/2)
    end

    def account(%{data: %{account_type: :business}} = menu, _payload) do
      menu 
      |> ExUssd.set(name: "business Account")
      |> ExUssd.set(resolve: &business_account/2)
   end

    def home(menu, _payload) do
      data = %{user_name: "john_doe", account_type: :personal}
      menu 
      |> ExUssd.set(title: "Welcome")
      |> ExUssd.set(data: data)
      |> ExUssd.add(ExUssd.new(name: "Product A", resolve: &product_a/2))
      |> ExUssd.add(ExUssd.new(name: "Product B", resolve: &product_b/2))
      |> ExUssd.add(ExUssd.new(name: "Product C", resolve: &product_c/2))
      |> ExUssd.add(ExUssd.new(&account/2))
      |> ExUssd.add(ExUssd.new(name: "Enter Pin", resolve: __MODULE__))
    end

    def personal_account(%{data: %{user_name: user_name}} = menu, _payload) do
      # send SMS notification
       menu |> ExUssd.set(title: "This is #{user_name}'s personal account")
    end

    def business_account(menu, _payload) do
       menu |> ExUssd.set(title: "This is a business account")
    end

    def ussd_init(menu, _) do
      menu
      |> ExUssd.set(title: "Enter your PIN")
    end

    def ussd_callback(menu, payload, _metadata) do
      if payload.text == "5555" do
        menu
        |> ExUssd.set(title: "You have Entered the Secret Number, 5555")
        |> ExUssd.set(should_close: true)
      end
    end
  end