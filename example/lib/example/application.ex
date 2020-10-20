defmodule Example.Application do
  use Application
  require Logger

  def start(_type, _args) do
    port = Application.get_env(:example, :port, 5000)

    children = [
      Plug.Cowboy.child_spec(scheme: :http, plug: Example.Endpoints, port: port)
    ]

    Logger.info("App Started on Port #{port}")

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
