defmodule ExUssd.Registry do
  @moduledoc """
  Registry for USSD session.
  """
  use GenServer

  defmodule State do
    @moduledoc false
    defstruct [:home, :current, route: []]
  end

  def init(_opts), do: {:ok, %State{}}

  defp via_tuple(session), do: {:via, Registry, {:session_registry, session}}

  def start(session), do: GenServer.start_link(__MODULE__, 0, name: via_tuple(session))

  def lookup(session) do
    case Registry.lookup(:session_registry, session) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  def stop(session) do
    case lookup(session) do
      {:ok, pid} -> Process.exit(pid, :shutdown)
      _ -> {:error, :not_found}
    end
  end

  def fetch_current(session), do: GenServer.call(via_tuple(session), {:fetch_current})
  def fetch_home(session), do: GenServer.call(via_tuple(session), {:fetch_home})
  def fetch_route(session), do: GenServer.call(via_tuple(session), {:fetch_route})

  def handle_call({:fetch_current}, _from, %State{current: current} = state),
    do: {:reply, current, state}

  def handle_call({:fetch_home}, _from, %State{home: home} = state), do: {:reply, home, state}

  def handle_call({:fetch_route}, _from, %State{route: route} = state), do: {:reply, route, state}
end
