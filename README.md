# ExUssd

[![Actions Status](https://github.com/beamkenya/ex_ussd/workflows/Elixir%20CI/badge.svg)](https://github.com/beamkenya/ex_ussd/actions) ![Hex.pm](https://img.shields.io/hexpm/v/ex_ussd) ![Hex.pm](https://img.shields.io/hexpm/dt/ex_ussd)

## Introduction

> ExUssd lets you create simple, flexible, and customizable USSD interface.
> Under the hood ExUssd uses Elixir Registry to create and route individual USSD session.

## Installation

[available in Hex](https://hexdocs.pm/ex_ussd), the package can be installed
by adding `ex_ussd` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_ussd, "0.1.3"}
  ]
end
```

## Example 
Checkout The example folder.

### Simple USSD menu
Implement ExUssd `init/2` callback.
Use `ExUssd.set/2` to set USSD value

```elixir
@allowed_fields [
    :error, # -> Custom error message, Used in the `callback/2`
    :title, # -> USSD menu title
    :next, # -> %{name: "MORE", next: "98", delimiter: ":"}
    :previous, # -> %{name: "BACK", previous: "0", delimiter: ":"}
    :should_close, # -> Indicate Menu state, default `false`
    :split, # -> Set split menu list by,  default 7
    :delimiter, # -> Set delimiter style,  ":"
    :continue, # -> Navigation state, Used in the `callback/2`
    :default_error, # -> Set default error message, "Invalid Choice\n", Used in the `init/2`
    :show_navigation # Show navigation, default `true`  
  ]
```

```elixir
  defmodule MyHomeHandler do
    use ExUssd.Handler
    def init(menu, _api_parameters) do
      menu 
      |> ExUssd.set(title: "Welcome")
    end
  end

  menu = ExUssd.new(name: "Home", handler: MyHomeHandler)

  api_parameters = %{"service_code" => "*544#", "session_id" => "session_01", "text" => ""}

  ExUssd.goto(menu: menu, api_parameters: api_parameters)

  {:ok, %{menu_string: "Welcome", should_close: false}}
```

### End USSD Session

Manually close USSD session, Use `ExUssd.end_session/1` it takes the `session_id` as params

```elixir
  defmodule MyHomeHandler do
    use ExUssd.Handler
    def init(menu, _api_parameters) do
      menu 
      |> ExUssd.set(title: "Welcome")
      |> ExUssd.set(should_close: true)
    end
  end

  menu = ExUssd.new(name: "Home", handler: MyHomeHandler)

  api_parameters = %{"service_code" => "*544#", "session_id" => "session_01", "text" => ""}

  ExUssd.goto(menu: menu, api_parameters: api_parameters)
    |> case do
    {:ok, %{menu_string: menu_string, should_close: false}} ->
      "CON " <> menu_string

    {:ok, %{menu_string: menu_string, should_close: true}} ->
      # End Session
      ExUssd.end_session(session_id: "session_01")

      "END " <> menu_string
    end
```

### USSD Simple List
Use `ExUssd.add/2` to add to USSD menu list.
The USSD menu list is `[]` by default.

```elixir
  defmodule ProductAHandler do
    use ExUssd.Handler
    def init(menu, _api_parameters) do
      menu |> ExUssd.set(title: "selected product a")
    end
  end

  defmodule ProductBHandler do
    use ExUssd.Handler
    def init(menu, _api_parameters) do
      menu |> ExUssd.set(title: "selected product b")
    end
  end

  defmodule ProductCHandler do
    use ExUssd.Handler
    def init(menu, _api_parameters) do
      menu 
      |> ExUssd.set(title: "selected product c")
    end
  end
  
  defmodule MyHomeHandler do
    use ExUssd.Handler
    def init(menu, _api_parameters) do
      menu 
      |> ExUssd.set(title: "Welcome")
      |> ExUssd.add(ExUssd.new(name: "Product A", handler: ProductAHandler))
      |> ExUssd.add(ExUssd.new(name: "Product B", handler: ProductBHandler))
      |> ExUssd.add(ExUssd.new(name: "Product C", handler: ProductCHandler))
    end
  end

  menu = ExUssd.new(name: "Home", handler: MyHomeHandler)
```

### USSD Nested List
Use `ExUssd.add/2` to add to USSD menu list on Individual USSD menu.

```elixir
  
  defmodule ProductCHandler do
    use ExUssd.Handler
    def init(menu, _api_parameters) do
      menu 
      |> ExUssd.set(title: "selected product c")
    end
  end
  
  defmodule ProductBHandler do
    use ExUssd.Handler
    def init(menu, _api_parameters) do
      menu 
      |> ExUssd.set(title: "selected product b")
      |> ExUssd.add(ExUssd.new(name: "Product C", handler: ProductCHandler))
    end
  end

  defmodule ProductAHandler do
    use ExUssd.Handler
    def init(menu, _api_parameters) do
      menu 
      |> ExUssd.set(title: "selected product a")
      |> ExUssd.add(ExUssd.new(name: "Product B", handler: ProductBHandler))
    end
  end

  defmodule MyHomeHandler do
    use ExUssd.Handler
    def init(menu, _api_parameters) do
      menu 
      |> ExUssd.set(title: "Welcome")
      |> ExUssd.add(ExUssd.new(name: "Product A", handler: ProductAHandler))    
    end
  end

  menu = ExUssd.new(name: "Home", handler: MyHomeHandler)
```

### Using USSD `navigation_response/1`
Implement `navigation_response/1` function on your USSD handler module.
`navigation_response/1` callback returns navigation status.

#### Scenario  
User passes in invalid
 - payload {:error, api_parameters}

User passes in valid input, name navigated to next menu
 - payload {:ok, api_parameters}

```elixir
  # ...
  defmodule MyHomeHandler do
    use ExUssd.Handler
    def init(menu, _api_parameters) do
      menu 
      |> ExUssd.set(title: "Welcome")
      |> ExUssd.add(ExUssd.new(name: "Product A", handler: ProductAHandler))
      |> ExUssd.add(ExUssd.new(name: "Product B", handler: ProductBHandler))
      |> ExUssd.add(ExUssd.new(name: "Product C", handler: ProductCHandler))
    end

    def navigation_response(payload) do
      IO.inspect payload
    end
  end
  
  menu = ExUssd.new(name: "Home", handler: MyHomeHandler)
```

### Using USSD `callback/2`
Implement ExUssd `callback/2` in the event you need to validate the Users input 

#### Simple validation menu

```elixir
  # ...
  defmodule MyHomeHandler do
    use ExUssd.Handler
    def init(menu, _api_parameters) do
      menu 
      |> ExUssd.set(title: "Welcome")
      |> ExUssd.add(ExUssd.new(name: "Product A", handler: ProductAHandler))
      |> ExUssd.add(ExUssd.new(name: "Product B", handler: ProductBHandler))
      |> ExUssd.add(ExUssd.new(name: "Product C", handler: ProductCHandler))
    end

    def callback(menu, api_parameters) do
      case api_parameters.text == "5555" do
        true ->
          menu
          |> ExUssd.set(title: "You have Entered the Secret Number, 5555")
          |> ExUssd.set(should_close: true)
          |> ExUssd.set(continue: true)

        _ ->
          menu 
          |> ExUssd.set(continue: false)
      end
    end
  end

  menu = ExUssd.new(name: "Home", handler: MyHomeHandler)

  api_parameters = %{"service_code" => "*544#", "session_id" => "session_01", "text" => "5555"}

  ExUssd.goto(menu: menu, api_parameters: api_parameters)

  {:ok, %{menu_string: "You have Entered the Secret Number, 5555", should_close: false}}
```

#### Nested validation menu

```elixir
  # ...
  defmodule MyHomeHandler do
    use ExUssd.Handler
    def init(%{data: data} = menu, _api_parameters) do
      IO.inspect data
      menu 
      |> ExUssd.set(title: "Welcome")
      |> ExUssd.add(ExUssd.new(name: "Product A", handler: ProductAHandler))
      |> ExUssd.add(ExUssd.new(name: "Product B", handler: ProductBHandler))
      |> ExUssd.add(ExUssd.new(name: "Product C", handler: ProductCHandler))
    end

    def callback(menu, api_parameters) do
      case api_parameters.text == "5555" do
        true ->
          menu
          |> ExUssd.set(title: "You have Entered the Secret Number, 5555")
          |> ExUssd.set(should_close: true)
          |> ExUssd.set(continue: true)

        _ ->
          menu 
          |> ExUssd.set(continue: false)
      end
    end
  end

  defmodule PinHandler do
    use ExUssd.Handler
    def init(menu, _api_parameters) do
      menu 
      |> ExUssd.set(title: "Enter your pin number")
      |> ExUssd.set(show_navigation: false)
    end

    def callback(menu, api_parameters) do
      case api_parameters.text == "4321" do
        true ->
          menu
          # |> ExUssd.navigate(data: %{name: "John"}, handler: MyHomeHandler)
          |> ExUssd.navigate(handler: MyHomeHandler)
          |> ExUssd.set(continue: true)
        _ ->
          menu 
          |> ExUssd.set(error: "Wrong pin number\n")
          |> ExUssd.set(continue: false)
      end
    end

    def navigation_response(payload) do
      IO.inspect payload
    end
  end

  menu = ExUssd.new(name: "Check PIN", handler: PinHandler)
  # ...
```
### Using USSD `dynamic`

#### Dymanic Vertical menus

```elixir
  # ...
  defmodule SubCountyHandler do
    use ExUssd.Handler
    def init(%{data: %{name: name}} = menu, api_parameters) do
      # TODO: Fetch county sub locations by county_code
      # Make dynamic location menus for the county
      # Split by 6 / 7
      menu 
      |> ExUssd.set(title: "#{name} County")
    end
  end

  defmodule CountyHandler do
    use ExUssd.Handler
    def init(menu, _api_parameters) do
      menus =
        fetch_api()
        |> Enum.map(fn %{name: name} = data ->
          ExUssd.new(name: name, data: data)
        end)

      menu
      |> ExUssd.set(title: "List of Counties")
      |> ExUssd.dynamic(
        menus: menus,
        handler: App.Dymanic.Vertical.SubCountyHandler,
        orientation: :vertical
      )
    end

    def fetch_api do
      [
        %{county_code: 47, name: "Nairobi"},
        %{county_code: 01, name: "Mombasa"},
        %{county_code: 42, name: "Kisumu"}
      ]
    end
  end

  defmodule MyHomeHandler do
    use ExUssd.Handler
    def init(menu, _api_parameters) do
      menu 
      |> ExUssd.set(title: "Welcome")
      |> ExUssd.add(ExUssd.new(name: "Counties List", handler: CountyHandler))
    end
  end

  menu = ExUssd.new(name: "Home", handler: MyHomeHandler)
  # ...
  {:ok, %{
   menu_string: "List of Counties\n1:Nairobi\n2:Mombasa\n3:Kisumu\n0:BACK",
   should_close: false
 }}
```

#### Dymanic Horizontal menus
Note: The name value is Truncated after 140 characters

```elixir

  defmodule NewsHandler do
    use ExUssd.Handler
    def init(menu, _api_parameters) do
      menus = fetch_api() |> Enum.map(fn %{"title"=> title, "body"=> body} -> 
           ExUssd.new(name: title <> "\n" <> body)
      end)

      menu 
      |> ExUssd.set(title: "World News")
      |> ExUssd.dynamic(menus: menus, orientation: :horizontal)
    end

    def fetch_api do
    [
      %{
        "userId" => 1,
        "id" => 1,
        "title" => "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
        "body" =>
          "quia et suscipit suscipit recusandae consequuntur expedita et cum reprehenderit molestiae ut ut quas totam nostrum rerum est autem sunt rem eveniet architecto"
      },
      %{
        "userId" => 1,
        "id" => 2,
        "title" => "qui est esse",
        "body" =>
          "est rerum tempore vitae sequi sint nihil reprehenderit dolor beatae ea dolores neque fugiat blanditiis voluptate porro vel nihil molestiae ut reiciendis qui aperiam non debitis possimus qui neque nisi nulla"
      },
      %{
        "userId" => 1,
        "id" => 3,
        "title" => "ea molestias quasi exercitationem repellat qui ipsa sit aut",
        "body" =>
          "et iusto sed quo iure voluptatem occaecati omnis eligendi aut ad voluptatem doloribus vel accusantium quis pariatur molestiae porro eius odio et labore et velit aut"
      }
    ]
    end
  end

  defmodule MyHomeHandler do
    use ExUssd.Handler
    def init(menu, _api_parameters) do
      menu 
      |> ExUssd.set(title: "BBC News")
      |> ExUssd.add(ExUssd.new(name: "News", handler: NewsHandler))
      # |> ExUssd.add(ExUssd.new(name: "WorkLife", handler: WorkLifeHandler))
      # |> ExUssd.add(ExUssd.new(name: "Sports", handler: SportsHandler))
    end
  end

  menu = ExUssd.new(name: "Home", handler: MyHomeHandler)
  # ...
  {:ok, %{
   menu_string: "1/3\nsunt aut facere repellat provident occaecati excepturi optio reprehenderit\nquia et suscipit suscipit recusandae consequuntur expedita et ...\n0:BACK 98:MORE",
   should_close: false
 }}
``` 

## Phoenix Simulator
Update your router's configuration to forward requests to ExUssd Simlutate with a `menu` entry and `phone_numbers` list

```elixir
# lib/my_app_web/router.ex
use MyAppWeb, :router

import ExUssd
...

if Mix.env() == :dev do
  scope "/" do
    pipe_through :browser
    simulate "/simulator",
      menu: ExUssd.new(name: "Home", handler: MyHomeHandler),
      phone_numbers: ["254700100100", "254700200200", "254700300300"]
  end
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_ussd](https://hexdocs.pm/ex_ussd).

