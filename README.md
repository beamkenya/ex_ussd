# ExUssd
A USSD Wrapper, compatible with 
[Infobip API](https://www.infobip.com/), [Africastalking API](https://africastalking.com), [Hubtel API](https://developers.hubtel.com/reference#ussd).

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

## Configuration

Create a copy of `config/dev.exs` or `config/prod.exs` from `config/dev.sample.exs`
Use the `provider` key to set the ussd vendor.

Add below config to dev.exs / prod.exs files

```elixir
config :ex_ussd, :provider, Infobip
```

### Quick Examples

```elixir
  iex> ExUssd.goto(
        internal_routing: %{text: "*544#", session_id: "session_01", service_code: "*544#"},
        menu: ExUssd.Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu |> Map.put(:title, "Home Page: Welcome")
        end
        ),
        api_parameters: %{
          sessionId: "session_01",
          phoneNumber: "254722000000",
          networkCode: "Safaricom",
          serviceCode: "*544#",
          text: "1"
          }
        )

  {:ok, %{responseExitCode: 200, responseMessage: "", shouldClose: false, ussdMenu: "Home Page: Welcome"}
```

#### Creating Menu's
```elixir
  iex> ExUssd.Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
          |> Map.put(:title, "Welcome Name")
        end
      )
```

#### Creating Menu's With Children

```elixir
  iex> ExUssd.Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->
          menu
          |> Map.put(:title, "Welcome Name")
          |> Map.put(:menu_list,
            [
              Menu.render(
              name: "Products",
              handler: fn menu, _api_parameters, _should_handle ->
                menu
                  |> Map.put(:title, "Our Product Catelog")
                  |> Map.put(:menu_list,
                  [
                    Menu.render(
                      name: "Product A",
                      handler: fn menu, _api_parameters, _should_handle ->
                        menu
                          |> Map.put(:title, "Product A Description")
                      end),
                      Menu.render(
                      name: "Product B",
                      handler: fn menu, _api_parameters, _should_handle ->
                        menu
                          |> Map.put(:title, "Product B Description")
                      end)
                    ])
                  ])
              end),
              Menu.render(
              name: "Exit",
              handler: fn menu, _api_parameters, _should_handle ->
                menu
                  |> Map.put(:title, "Thank you for Using Our Service")
                  |> Map.put(:should_close, true)
              end)
            ])
        end
      )
```

#### Creating Menu's that can Handle/Validate Client Input

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
                        |> Map.put(:title, "Welcome Back")
                        |> Map.put(:success, true)
                      _->
                        menu |> Map.put(:error, "Invalid Pin Number")
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
```
