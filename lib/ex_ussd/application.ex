defmodule ExUssd.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: :session_registry}
    ]

    opts = [strategy: :one_for_one, name: ExUssd.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
