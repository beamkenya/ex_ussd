# ExUssd

[![Actions Status](https://github.com/beamkenya/ex_ussd/workflows/Elixir%20CI/badge.svg)](https://github.com/beamkenya/ex_ussd/actions) ![Hex.pm](https://img.shields.io/hexpm/v/ex_ussd) ![Hex.pm](https://img.shields.io/hexpm/dt/ex_ussd)
[![Coverage Status](https://coveralls.io/repos/github/beamkenya/ex_ussd/badge.svg?branch=develop)](https://coveralls.io/github/beamkenya/ex_ussd?branch=develop)

## Introduction

> ExUssd lets you create simple, flexible, and customizable USSD interface.
> Under the hood ExUssd uses Elixir Registry to create and route individual USSD session.

## Sections

- [Installation](#Installation)
- [Gateway Providers](#providers)
- [Configuration](#Configuration)
- [Documentation](#Documentation)
- [Contribution](#contribution)
- [Contributors](#contributors)
- [Licence](#licence)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_ussd` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_ussd, "~> 0.1.1"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_ussd](https://hexdocs.pm/ex_ussd).

## Providers

ExUssd currently supports

[Africastalking API](https://africastalking.com)

[Infobip API](https://www.infobip.com/)

## Configuration

To Use One of the above gateway providers for your project
Create a copy of `config/dev.exs` or `config/prod.exs` from `config/dev.sample.exs`
Use the `gateway` key to set the ussd vendor.

### AfricasTalking

Add below config to dev.exs / prod.exs files

```elixir
config :ex_ussd, :gateway, AfricasTalking
```

### Infobip

Add below config to dev.exs / prod.exs files

```elixir
config :ex_ussd, :gateway, Infobip
```

## Documentation

ExUssd supports Ussd customizations through `Menu` struct via the render function

  - `name`: (Public) This is the value display when Menu is rendered as menu_list. check more on `menu_list`,
  - `handler`: (Public) A callback that modifies the current menu struct. Implemented via ExUssd.Handler
  - `callback`: (Internal) A callback function that takes the `handler` callback. This function is triggered when the client is at that menu position.
  - `title`: (Public) Outputs the ussd's title,
  - `menu_list`: (Public) Takes a list of Ussd Menu struct,
  - `error`: (Public) A custom validation error message for `validation_menu`,
  - `show_navigation`: (Public) set to false to hide navigation menu,
  - `next`: (Public) navigate's the next menu chunk, default `"98"`,
  - `previous`: (Public) navigate's the previous menu chunk or the previous menu struct default `"0"`,,
  - `split`: (Public) This is used to set the chunk size value when rendering menu_list. default value size `7`,
  - `should_close`: (Public) This triggers ExUssd to end the current registry session,
  - `display_style`: (Public) This is used to change default's display style, default ":"
  - `parent`: (Internal) saves the previous menu struct to the current menu in order to facilitate navigation,
  - `validation_menu`: (Public) Its a special Menu struct that enables the developer to validate the client input,
  - `data`: (Public) takes data as Props that will be attached to the children menu struct,
  - `default_error_message`:(Public)  This the default error message shown on invalid input. default `"Invalid Choice\n"`

### Ussd Menu with title Only

```elixir
defmodule MyHomeHandler do
   @behaviour ExUssd.Handler
  def handle_menu(menu, api_parameters, should_handle) do
     menu |> Map.put(:title, "Welcome")
   end
end
menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)
ExUssd.goto(
  internal_routing: %{text: "", session_id: "session_01", service_code: "*544#"},
  menu: menu,
  api_parameters: %{"sessionId" => "session_01", "phoneNumber" => "254722000000", "networkCode" =>,"Safaricom", "serviceCode" => "*544#", "text" => "" }
  )
{:ok, "CON Welcome"}
```
### Ussd Menu with title and menu_list

```elixir
defmodule ProductAHandler do
    @behaviour ExUssd.Handler
    def handle_menu(menu, _api_parameters, _should_handle) do
      menu |> Map.put(:title, "selected product a")
    end
  end

defmodule ProductBHandler do
  @behaviour ExUssd.Handler
  def handle_menu(menu, _api_parameters, _should_handle) do
    menu |> Map.put(:title, "selected product b")
  end
end

defmodule ProductCHandler do
  @behaviour ExUssd.Handler
  def handle_menu(menu, _api_parameters, _should_handle) do
    menu |> Map.put(:title, "selected product c")
  end
end

defmodule MyHomeHandler do
  @behaviour ExUssd.Handler
  def handle_menu(menu, _api_parameters, _should_handle) do
    menu
    |> Map.put(:title, "Welcome")
    |> Map.put(
      :menu_list,
      [
        ExUssd.Menu.render(name: "Product A", handler: ProductAHandler),
        ExUssd.Menu.render(name: "Product B", handler: ProductBHandler),
        ExUssd.Menu.render(name: "Product C", handler: ProductCHandler)
      ]
    )
  end
end
menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)
ExUssd.goto(
  internal_routing: %{text: "", session_id: "session_01", service_code: "*544#"},
  menu: menu,
  api_parameters: %{"sessionId" => "session_01", "phoneNumber" => "254722000000", "networkCode" =>,"Safaricom", "serviceCode" => "*544#", "text" => "" }
)

{:ok, "CON Welcome\n1:Product A\n2:Product B"}
# simulate 1
menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)
ExUssd.goto(
  internal_routing: %{text: "1", session_id: "session_01", service_code: "*544#"},
  menu: menu,
  api_parameters: %{"sessionId" => "session_01", "phoneNumber" => "254722000000", "networkCode" =>,"Safaricom", "serviceCode" => "*544#", "text" => "1" }
  )
{:ok, "CON selected product a\n0:BACK"}
```
### Ussd validation Menu

```elixir
defmodule PinValidateHandler do
  @behaviour ExUssd.Handler
  def handle_menu(menu, api_parameters, should_handle) do
    case should_handle do
      true ->
        case api_parameters.text == "5555" do
          true ->
            menu
            |> Map.put(:title, "success, thank you.")
            |> Map.put(:should_close, true)

          _ ->
            menu |> Map.put(:error, "Wrong pin number\n")
        end

      false ->
        menu
    end
  end
end

defmodule MyHomeHandler do
  @behaviour ExUssd.Handler
  def handle_menu(menu, _api_parameters, _should_handle) do
    menu
    |> Map.put(:title, "Enter your pin number")
    |> Map.put(:validation_menu, ExUssd.Menu.render(name: "", handler: PinValidateHandler))
  end
end

menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)
ExUssd.goto(
  internal_routing: %{text: "", session_id: "session_01", service_code: "*544#"},
  menu: menu,
  api_parameters: %{"sessionId" => "session_01", "phoneNumber" => "254722000000", "networkCode" =>,"Safaricom", "serviceCode" => "*544#", "text" => "" }
)
{:ok, "CON Enter your pin number"}

# simulate wrong pin
menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)
ExUssd.goto(
  internal_routing: %{text: "3339", session_id: "session_01", service_code: "*544#"},
  menu: menu,
  api_parameters: %{"sessionId" => "session_01", "phoneNumber" => "254722000000", "networkCode" =>,"Safaricom", "serviceCode" => "*544#", "text" => "3339" }
)
{:ok, "CON Wrong pin number\nEnter your pin number"}

# simulate correct pin
menu = ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)
ExUssd.goto(
  internal_routing: %{text: "5555", session_id: "session_01", service_code: "*544#"},
  menu: menu,
  api_parameters: %{"sessionId" => "session_01", "phoneNumber" => "254722000000", "networkCode" =>,"Safaricom", "serviceCode" => "*544#", "text" => "5555" }
)
{:ok, "END success, thank you."}
```

### Testing
To test your USSD menu, ExUssd provides a `simulate` function that helps you test menu rendering and logic implemented by mimicking USSD gateway callback.

```elixir
  iex> menu = ExUssd.Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu |> Map.put(:title, "Welcome")
        end
        )
  iex> ExUssd.simulate(menu: menu, text: "")

  {:ok, "CON Welcome"}
```
## Contribution

If you'd like to contribute, start by searching through the [issues](https://github.com/beamkenya/ex_ussd/issues) and [pull requests](https://github.com/beamkenya/ex_ussd/pulls) to see whether someone else has raised a similar idea or question.
If you don't see your idea listed, [Open an issue](https://github.com/beamkenya/ex_ussd/issues).

Check the [Contribution guide](contributing.md) on how to contribute.

## Contributors

Auto-populated from:
[contributors-img](https://contributors-img.firebaseapp.com/image?repo=beamkenya/ex_ussd)

<a href="https://github.com/beamkenya/ex_ussd/graphs/contributors">
  <img src="https://contributors-img.firebaseapp.com/image?repo=beamkenya/ex_ussd" />
</a>

## Licence

ExPesa is released under [MIT License](https://github.com/appcues/exsentry/blob/master/LICENSE.txt)

[![license](https://img.shields.io/github/license/mashape/apistatus.svg?style=for-the-badge)](#)