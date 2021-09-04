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

## Installation

[available in Hex](https://hexdocs.pm/ex_ussd), the package can be installed
by adding `ex_ussd` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_ussd, "0.2.0"}
  ]
end

```

## Quick Examples

##### Resolver module

```elixir
defmodule Api.HomeResolver do
  use ExUssd
  def ussd_init(menu, _) do
    menu
    |> ExUssd.set(title: "Enter your PIN")
  end

  def ussd_callback(menu, payload, _) do
    if payload.text == "5555" do
      menu
      |> ExUssd.set(title: "You have Entered the Secret Number, 5555")
      |> ExUssd.set(should_close: true)
    end
  end
end

menu = ExUssd.new(name: "Home", resolve: Api.HomeResolver)
```

##### Resolver function
```elixir
defmodule Api.HomeResolver do
  use ExUssd
  def welcome(menu, payload) do
    menu
    |> ExUssd.set(title: "Welcome, Your account is now active")
  end
end

menu = ExUssd.new(name: "Home", resolve: &Api.HomeResolver.welcome/2)
```

##### Gateway Response
```elixir
case ExUssd.goto(menu: menu, payload: %{service_code: "*544#", session_id: "se1",text: ""}) do
  {:ok, %{menu_string: menu_string, should_close: false}} ->
    "CON " <> menu_string

  {:ok, %{menu_string: menu_string, should_close: true}} ->
    # End Session
    ExUssd.end_session(session_id: "se1")

    "END " <> menu_string
end

"CON Enter your PIN" / "CON Welcome, Your account is now active"
```

## Test
##### Resolver module
```elixir
...
iex> menu = ExUssd.new(name: "Home", resolve: HomeResolver)

iex> ExUssd.to_string(menu, :ussd_init, [])
{:ok, %{menu_string: "Enter your PIN", should_close: false}}

iex> ExUssd.to_string(menu, :ussd_callback, [payload: %{text: "5555", phoneNumber: "254722000000"}])
{:ok, %{menu_string: "You have Entered the Secret Number, 5555", should_close: true}}
```
##### Resolver function
```elixir
...
iex> menu = ExUssd.new(name: "Home", resolve: &Api.HomeResolver.welcome/2)

iex> ExUssd.to_string(menu, [])
{:ok, %{menu_string: "Welcome, Your account is now active", should_close: false}}

iex> ExUssd.to_string(menu, :ussd_init, [])
{:ok, %{menu_string: "Welcome, Your account is now active", should_close: false}}
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

