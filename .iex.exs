defmodule HomeResolver do
    use ExUssd

    def product_a(menu, _payload), do: menu |> ExUssd.set(title: "selected product a")
    def product_b(menu, _payload), do: menu |> ExUssd.set(title: "selected product b")
    def product_c(menu, _payload), do: menu |> ExUssd.set(title: "selected product c")

    def home(menu, _payload) do
      menu 
      |> ExUssd.set(title: "Welcome")
      |> ExUssd.add(ExUssd.new(name: "Product A", resolve: &product_a/2))
      |> ExUssd.add(ExUssd.new(name: "Product B", resolve: &product_b/2))
      |> ExUssd.add(ExUssd.new(name: "Product C", resolve: &product_c/2))
      |> ExUssd.add(ExUssd.new(name: "Enter Pin", resolve: __MODULE__))
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