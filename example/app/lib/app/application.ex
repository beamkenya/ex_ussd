defmodule App.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: App.Worker.start_link(arg)
      # {App.Worker, arg}
      Plug.Cowboy.child_spec(
          scheme: :http,
          plug: App.Endpoints,
          options: [
            port: 4000
          ]
        )
    ]

    Logger.info("App Started on Port 4000")

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: App.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
