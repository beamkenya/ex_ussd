# ExUssd

[![Actions Status](https://github.com/beamkenya/ex_ussd/workflows/Elixir%20CI/badge.svg)](https://github.com/beamkenya/ex_ussd/actions) ![Hex.pm](https://img.shields.io/hexpm/v/ex_ussd) ![Hex.pm](https://img.shields.io/hexpm/dt/ex_ussd)

Goals:
- An idiomatic, readable, and comfortable API for Elixir developers
- Extensibility based on small parts that do one thing well.
- Detailed error messages and documentation.
- A focus on robustness and production-level performance.


## Why Use ExUssd?
 ExUssd lets you create simple, flexible, and customizable USSD interface.
 Under the hood ExUssd uses Elixir Registry to create and route individual USSD session.

https://user-images.githubusercontent.com/23293150/124460086-95ebf080-dd97-11eb-87ab-605f06291563.mp4

# Getting Started
## Adding ExUssd to an application

To add ExUssd to your application application.

```elixir
defp deps do
  [
    {:ex_ussd, "~> 1.0"}
  ]
end
```

## Let's create a custom global values

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
# Usage
## ExUssd Callbacks

ExUssd provides you with 3 callbacks

    - `ussd_init/2` - It's invoked once when the user navigates to that perticular menu
    - `ussd_callback/3` - It's an optional callback that is invoked after `ussd_init/2` to validate the user input.
    - `ussd_after_callback/3` - It's an optional callback that is invoked after `ussd_callback` is invoked.

Create a new module:

```elixir
defmodule Api.HomeResolver do
  use ExUssd
  def ussd_init(menu, _) do
    ExUssd.set(menu, title: "Enter your PIN")
  end

  def ussd_callback(menu, payload, %{attempt: attempt}) do
    if payload.text == "5555" do
      menu
      |> ExUssd.set(title: "You have Entered the Secret Number, 5555")
      |> ExUssd.set(should_close: true)
    else
      ExUssd.set(menu, error: "Wrong PIN, attempt #{attempt}/3\n")
    end
  end

  def ussd_after_callback(%{error: true} = menu, _payload, %{attempt: 3}) do
    menu
    |> ExUssd.set(title: "Account is locked, you have entered the wrong PIN 3 times")
    |> ExUssd.set(should_close: true)
  end
end
```

Lets test the different ExUssd callbacks with `ExUssd.to_string/3`

First create menu

```elixir
menu = ExUssd.new(name: "PIN", resolve: Api.HomeResolver)
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

