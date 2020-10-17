# ExUssd

## Introduction
ExUssd was created out of a need to have a powerfully simple, flexible, and customizable Ussd interface
without the need create or manage ussd session letting focus on implementing the Ussd Logic. 
Under the hood ExUssd is implemented using Elixir Registry as a local, decentralized and scalable key-value process storage for ussd session.



## Sections
- [Installation](##Installation)
- [Providers](##providers)
- [Configuration](##Configuration)
- [Select Providers](##providers)
- [Create Ussd Menu](##Menu)
- [Render Ussd Menu](##Render-Menu)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_ussd` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_ussd, "~> 0.1.0"}
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

[Hubtel API](https://developers.hubtel.com/reference#ussd)


## Configuration
To Use One of the above providers for your project
Create a copy of `config/dev.exs` or `config/prod.exs` from `config/dev.sample.exs`
Use the `provider` key to set the ussd vendor.

### AfricasTalking
Add below config to dev.exs / prod.exs files

```elixir
config :ex_ussd, :provider, AfricasTalking
```

### Infobip
Add below config to dev.exs / prod.exs files

```elixir
config :ex_ussd, :provider, Infobip
```

### Hubtel
Add below config to dev.exs / prod.exs files

```elixir
config :ex_ussd, :provider, Hubtel
```

## Menu

ExUssd supports Ussd customizations through `Menu` struct via the render function

  - `handler` - This is a callback function that returns the menu struct, ussd api_parameters map and should_handle boolean.
    - menu - The menu struct is modified to produce ussd menu struct
    - api_parameters - This a map of ussd response call
    - should_handle - a check value, where ExUssd allows the developer to handle client input, more on `handle`, default is `false`

  - `name` - This is the value display when Menu is rendered as menu_list. check more on `menu_list`.

  - `title` - Outputs the ussd's title,
  ```elixir
  ExUssd.Menu.render(
          name: "Home",
          handler: fn menu, _api_parameters, _should_handle ->
            menu |> Map.put(:title, "Welcome")
          end
          )
  {:ok, "CON Welcome"}
  ```
  - `menu_list` - Takes a list of Ussd Menu
```elixir
  ExUssd.Menu.render(
          name: "Home",
          handler: fn menu, _api_parameters, _should_handle ->
            menu |> Map.put(:title, "Welcome")
            |> Map.put(:menu_list,
            [
              Menu.render(
              name: "Product A",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product a")
            ),
            Menu.render(
              name: "Product B",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product b")
            )]
          )
  {:ok, "CON Welcome\n1:Product A\n2:Product B"}
  # simulate 1
  {:ok, "CON selected product a\n0:BACK"}
  ```
  - `should_close` - This triggers ExUssd to display end the session state on the registry and display the correct preffix,
```elixir
  ExUssd.Menu.render(
          name: "Home",
          handler: fn menu, _api_parameters, _should_handle ->
            menu |> Map.put(:title, "Welcome")
            |> Map.put(:menu_list,
            [
              Menu.render(
              name: "Product A",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product a")
                |> Map.put(:should_close, true)
            ),
            Menu.render(
              name: "Product B",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product b")
                |> Map.put(:should_close, true)
            )]
          )
  {:ok, "CON Welcome\n1:Product A\n2:Product B"}
  # simulate 1
  {:ok, "END selected product a"}
  ```

  - `default_error_message` - Shows the error message on top of the title in case of an invalid input. default `"Invalid Choice\n"`
```elixir
  ExUssd.Menu.render(
          name: "Home",
          handler: fn menu, _api_parameters, _should_handle ->
            menu 
            |> Map.put(:default_error_message, "Invalid selection, try again\n")
            |> Map.put(:title, "Welcome")
            |> Map.put(:menu_list,
            [
              Menu.render(
              name: "Product A",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product a")
            ),
            Menu.render(
              name: "Product B",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product b")
            )]
          )
  {:ok, "CON Welcome\n1:Product A\n2:Product B"}
  # simulate 11
  {:ok, "CON Invalid selection, try again\nWelcome\n1:Product A\n2:Product B"}
  ```

  - `display_style` - Used change the default's display style ":",
```elixir
  ExUssd.Menu.render(
          name: "Home",
          handler: fn menu, _api_parameters, _should_handle ->
            menu 
            |> Map.put(:display_style, ")")
            |> Map.put(:title, "Welcome")
            |> Map.put(:menu_list,
            [
              Menu.render(
              name: "Product A",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product a")
            ),
            Menu.render(
              name: "Product B",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product b")
            )]
          )
  {:ok, "CON Welcome\n1)Product A\n2)Product B"}
  ```
  - `split` - This is used to set the chuck size value when rendering menu_list. default value `7`,
```elixir
  ExUssd.Menu.render(
          name: "Home",
          handler: fn menu, _api_parameters, _should_handle ->
            menu 
            |> Map.put(:split, 2)
            |> Map.put(:title, "Welcome")
            |> Map.put(:menu_list,
            [
              Menu.render(
              name: "Product A",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product a")
            ),
            Menu.render(
              name: "Product B",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product b")
            ),
            Menu.render(
              name: "Product C",
              handler: fn menu, _api_parameters, _should_handle ->
                menu |> Map.put(:title, "selected product c")
            )]
          )
  {:ok, "CON Welcome\n1:Product A\n2:Product B\n98:MORE"}
  # simulate 98
  {:ok, "CON Welcome\n3:Product C\n0:BACK"}
  ```
  - `next` - Used render the next menu chuck, default `"98"`,
  - `previous` - Ussd to navigate to the previous menu, default "0",

  - `handle` - To let ExUssd allow the developer to handle the client input, set the value to `true`, this will then trigger a callback call on the handler for the first menu of the menu list with should_handle value `true`, default `false`.

```elixir
  iex> ExUssd.Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
            |> Map.put(:title, "Enter Pin Number")
            |> Map.put(:menu_list,
            [
              Menu.render(
              name: "",
              handler: fn menu, api_parameters, should_handle ->
                case should_handle do
                  true ->
                    case api_parameters.text == "5342" do
                      true ->
                        menu
                        |> Map.put(:title, "your pin is valid, thank you.")
                        |> Map.put(:success, true)
                        |> Map.put(:should_close, true)
                      _->
                        menu |> Map.put(:error, "Wrong pin number\n")
                    end
                  false -> menu
                end
              end)
            ])
            |> Map.put(:handle, true)
            |> Map.put(:show_options, false)
        end
      )
    )

    {:ok, "CON Enter Pin Number"}
    ## simulate 5342
    {:ok, "END your pin is valid, thank you."}
    ## simulate 5555
    {:ok, "CON Wrong pin number\nEnter Pin Number"}
```

  - `error` - custom error message on failed validation/handling,
  - `success` - allows ExUssd to Render next menu on successful validation/handling,
  -`show_options` - hides menu list

## Render Menu
ExUssd to render `Menu` struct for different ussd providers. ExUssd provides `goto` function that starts and manages the ussd sessions.
The `goto` function receives the following parameters.
  - `internal_routing` - it takes a map with ussd text, session_id and serive_code
  - `menu` - Menu struct
  - `api_parameters` - api_parameters

```elixir
  iex> menu = ExUssd.Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu |> Map.put(:title, "Welcome")
        end
        ),
  iex> ExUssd.goto(
        internal_routing: %{text: "*544#", session_id: "session_01", service_code: "*544#"},
        menu: menu
        api_parameters: %{ sessionId: "session_01", phoneNumber: "254722000000", networkCode:"Safaricom",serviceCode: "*544#", text: "1" }
        )

  {:ok, "CON Welcome"}
```