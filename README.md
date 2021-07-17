# ExUssd

[![Actions Status](https://github.com/beamkenya/ex_ussd/workflows/Elixir%20CI/badge.svg)](https://github.com/beamkenya/ex_ussd/actions) ![Hex.pm](https://img.shields.io/hexpm/v/ex_ussd) ![Hex.pm](https://img.shields.io/hexpm/dt/ex_ussd)

## Introduction

> ExUssd lets you create simple, flexible, and customizable USSD interface.
> Under the hood ExUssd uses Elixir Registry to create and route individual USSD session.

https://user-images.githubusercontent.com/23293150/124460086-95ebf080-dd97-11eb-87ab-605f06291563.mp4

# ExUssd architecture

The following tree of documents outlines the basic design of the Exussd
architecture, and how to write code against the API callbacks.

The basic architecture of ExUssd is inspired by languages such as [phoenix_live_dashboard], 
and in part the nx library [nx].

[phoenix_live_dashboard]: https://github.com/phoenixframework/phoenix_live_dashboard
[nx]: https://github.com/elixir-nx/nx

ExUssd session are managed by elixir registry supervisor which will keep the step of users
ussd sessions, Generally they go through the following steps.

1. Create Menu (calls `ExUssd.new(...)`)
2. Initialization (calls `ExUssd.goto(...)`)
4. Shutdown (calls `ExUssd.end_session(...)`)

Ussd Sessions are managed by ExUssd library.

## Installation

[available in Hex](https://hexdocs.pm/ex_ussd), the package can be installed
by adding `ex_ussd` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_ussd, "0.1.9"}
  ]
end
```

