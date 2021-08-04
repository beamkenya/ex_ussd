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

  def start(session), do: GenServer.start_link(__MODULE__, [], name: via_tuple(session))

  def lookup(session) do
    case Registry.lookup(:session_registry, session) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  def stop(session_id) do
    case lookup(session_id) do
      {:ok, pid} -> Process.exit(pid, :shutdown)
      _ -> {:error, :not_found}
    end
  end

  def add_route(session, route), do: GenServer.call(via_tuple(session), {:add_route, route})
  def fetch_current(session), do: GenServer.call(via_tuple(session), {:fetch_current})
  def fetch_home(session), do: GenServer.call(via_tuple(session), {:fetch_home})
  def fetch_state(session), do: GenServer.call(via_tuple(session), {:fetch_state})
  def fetch_route(session), do: GenServer.call(via_tuple(session), {:fetch_route})
  def next_route(session), do: GenServer.call(via_tuple(session), {:next_route})
  def route_back(session), do: GenServer.call(via_tuple(session), {:route_back})
  def set(session, route), do: GenServer.call(via_tuple(session), {:set, route})
  def set_current(session, menu), do: GenServer.call(via_tuple(session), {:set_current, menu})
  def set_home(session, menu), do: GenServer.call(via_tuple(session), {:set_home, menu})
  def set_depth(session, depth), do: GenServer.call(via_tuple(session), {:set_depth, depth})

  def handle_call({:add_route, route}, _from, %State{route: routes} = state) when is_map(route) do
    state = Map.put(state, :route, [route | routes])
    {:reply, state, state}
  end

  def handle_call({:fetch_current}, _from, %State{current: current} = state),
    do: {:reply, current, state}

  def handle_call({:fetch_home}, _from, %State{home: home} = state), do: {:reply, home, state}

  def handle_call({:fetch_state}, _from, state), do: {:reply, state, state}

  def handle_call({:fetch_route}, _from, %State{route: route} = state), do: {:reply, route, state}

  def handle_call({:next_route}, _from, %State{route: [head | tail]} = state) do
    new_state = Map.put(state, :route, [Map.put(head, :depth, head[:depth] + 1) | tail])
    {:reply, new_state, new_state}
  end

  def handle_call({:route_back}, _from, %State{route: [%{depth: depth} = head | tail]} = state) do
    if head[:depth] == 1 do
      route = with [] <- tail, do: [%{depth: 1, text: "555"}]
      {:reply, head, Map.put(state, :route, route)}
    else
      new_head = Map.put(head, :depth, depth - 1)
      new_state = [new_head | tail]
      {:reply, new_head, Map.put(state, :route, new_state)}
    end
  end

  def handle_call({:set, route}, _from, state) when is_list(route) do
    state = Map.put(state, :route, route)
    {:reply, state, state}
  end

  def handle_call({:set_current, menu}, _from, state) do
    {:reply, menu, Map.put(state, :current, menu)}
  end

  def handle_call({:set_home, menu}, _from, state) do
    {:reply, menu, Map.put(state, :home, menu)}
  end

  def handle_call({:set_depth, depth}, _from, %State{route: [head | tail]} = state) do
    new_state = Map.put(state, :route, [Map.put(head, :depth, depth) | tail])
    {:reply, new_state, new_state}
  end
end
