# ExUssd

[![Actions Status](https://github.com/beamkenya/ex_ussd/workflows/Elixir%20CI/badge.svg)](https://github.com/beamkenya/ex_ussd/actions) ![Hex.pm](https://img.shields.io/hexpm/v/ex_ussd) ![Hex.pm](https://img.shields.io/hexpm/dt/ex_ussd)

Goals:
- An idiomatic, readable, and comfortable API for Elixir developers
- Extensibility based on small parts that do one thing well.
- Detailed error messages and documentation.
- A focus on robustness and production-level performance.

## Table of contents

- [Why Use ExUssd](#why-use-exussd)
- [Documentation](#documentation)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Contribution](#contribution)
- [Contributors](#contributors)
- [Licence](#licence)


## Why Use ExUssd?
 ExUssd lets you create simple, flexible, and customizable USSD interface.
 Under the hood ExUssd uses Elixir Registry to create and route individual USSD session.

https://user-images.githubusercontent.com/23293150/124460086-95ebf080-dd97-11eb-87ab-605f06291563.mp4

## Documentation
The docs can be found at [https://hexdocs.pm/ex_ussd](https://hexdocs.pm/ex_ussd).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_ussd` to your list of dependencies in `mix.exs`:


```elixir
defp deps do
  [
    {:ex_ussd, "~> 1.0.0-rc-1"}
  ]
end
```

## Configuration

Add to your `config.exs`

 ```elixir
# config/config.exs
# TODO: This are example values, replace them with your own
config :ex_ussd,
  nav: [
    ExUssd.Nav.new(type: :home, name: "HOME", match: "00", reverse: true, orientation: :vertical),
    ExUssd.Nav.new(type: :back, name: "BACK", match: "0", right: 1),
    ExUssd.Nav.new(type: :next, name: "MORE", match: "98")
      ],
  delimiter: ").",
  default_error: "invalid input,try again\n"
```

## Usage

### Settable Fields

* **`:data`** Set data to pass through to next menu. N/B - ExUssd menu are stateful unless using ExUssd.new/2 with `:name` and `:resolve` as arguments;
  ```elixir
  data = %{name: "John Doe"}
  # stateful
  menu
  |> ExUssd.set(data: data)
  |> ExUssd.add(ExUssd.new("Check Balance", &check_balance/2))
 
  # stateless
  menu
  |> ExUssd.add(ExUssd.new(data: data, name: "Check Balance", resolve: &check_balance/2))
    ```

* **`:delimiter`** Set's menu style delimiter. Default- `:`
* **`:default_error`** Default error shown on invalid input
* **`:error`** Set custom error message
* **`:name`** Sets the name of the menu
* **`:nav`** Its used to create a new ExUssd Nav menu
* **`:orientation`** Sets the menu orientation. Available option;
  - `:horizontal` - Left to right. Blog/articles style menu
  - `vertical` - Top to bottom(default)
* **`:resolve`** Navigates(invokes the next `ussd_init/2`) to the next menu
* **`:should_close`** Indicate whether to USSD session should end or continue
* **`:show_navigation`** Set show navigation menu. Default - `true`
* **`:split`** Set menu batch size. Default - 7
* **`:title`** Set menu title


### ExUssd Callbacks

ExUssd provides you with 3 callbacks

* **`ussd_init/2`**
  It's invoked once when the user navigates to that particular menu

* **`ussd_callback/3`**
  It's an optional callback that is invoked after `ussd_init/2` to validate the user input.

* **`ussd_after_callback/3`**
  It's an optional callback that is invoked after `ussd_callback/3` is invoked.


#### Example
Create a new module:

```elixir
defmodule ApiWeb.HomeResolver do
  use ExUssd
  def ussd_init(menu, _) do
    ExUssd.set(menu, title: "Enter your PIN")
  end

  def ussd_callback(menu, payload, %{attempt: attempt}) do
    if payload.text == "5555" do
      ExUssd.set(menu, resolve: &success_menu/2)
    else
      ExUssd.set(menu, error: "Wrong PIN, attempt #{attempt}/3\n")
    end
  end

  def ussd_after_callback(%{error: true} = menu, _payload, %{attempt: 3}) do
    menu
    |> ExUssd.set(title: "Account is locked, you have entered the wrong PIN 3 times")
    |> ExUssd.set(should_close: true)
  end

  def success_menu(menu, _) do
    menu
    |> ExUssd.set(title: "You have Entered the Secret Number, 5555")
    |> ExUssd.set(should_close: true)
  end
end
```

Let's test the different ExUssd callbacks with `ExUssd.to_string/3`

create menu

```elixir
menu = ExUssd.new(name: "PIN", resolve: ApiWeb.HomeResolver)
```

**`ussd_init/2`**

```elixir
iex> ExUssd.to_string(menu, :ussd_init, [])
{:ok, %{menu_string: "Enter your PIN", should_close: false}}
```

**`ussd_callback/3`**

```elixir
iex> ExUssd.to_string(menu, :ussd_callback, [payload: %{text: "5555"}, init_text: "1"])
{:ok, %{menu_string: "You have Entered the Secret Number, 5555", should_close: true}}

iex> ExUssd.to_string(menu, :ussd_callback, [payload: %{text: "42", attempt: 3}, init_text: "1"])
{:ok, %{menu_string: "Wrong PIN, attempt 3/3\nEnter your PIN", should_close: false}}
```

**`ussd_after_callback/3`**

```elixir
iex> ExUssd.to_string(menu, :ussd_after_callback, [payload: %{text: "42", attempt: 3}, init_text: "1"])
{:ok,
 %{
   menu_string: "Account is locked, you have entered the wrong PIN 3 times",
   should_close: true
 }}
```

### ExUssd Menu List
```elixir
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

    def check_balance(%{data: %{account_type: account_type}} = menu, _payload) do
      if (account_type == :personal) do
        menu
        |> ExUssd.set(resolve: &personal_account_balance/2)
      else
        menu
        |> ExUssd.set(resolve: &business_account_balance/2)
      end
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
      |> ExUssd.add(ExUssd.new("Check Balance", &check_balance/2))
      |> ExUssd.add(ExUssd.new(name: "Enter Pin", resolve: __MODULE__))
    end
  end
```


## Contribution

If you'd like to contribute, start by searching through the [issues](https://github.com/beamkenya/ex_ussd/issues) and [pull requests](https://github.com/beamkenya/ex_ussd/pulls) to see whether someone else has raised a similar idea or question.
If you don't see your idea listed, [Open an issue](https://github.com/beamkenya/ex_ussd/issues).

Check the [Contribution guide](contributing.md) on how to contribute.

## Contributors

Auto-populated from:
[contributors-img](https://contributors-img.firebaseapp.com/image?repo=beamkenya/ex_ussd)

<a href="https://github.com/beamkenya/ex_pesa/graphs/contributors">
  <img src="https://contributors-img.firebaseapp.com/image?repo=beamkenya/ex_ussd" />
</a>

## Licence

ExUssd is released under [MIT License](https://github.com/appcues/exsentry/blob/master/LICENSE.txt)

[![license](https://img.shields.io/github/license/mashape/apistatus.svg?style=for-the-badge)](#)

