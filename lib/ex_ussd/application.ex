defmodule ExUssd.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # A local, decentralized and scalable key-value process storage for Client Session
      {Registry, keys: :unique, name: :session_registry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExUssd.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
