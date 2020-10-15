defmodule ExUssd.State.Registry do
  use GenServer
  def init(_opts), do: {:ok, %{routes: []}}

  defp via_tuple(session_id), do: {:via, Registry, {:session_registry, session_id}}

  def start(session) do
    name = via_tuple(session)
    GenServer.start_link(__MODULE__, 0, name: name)
    :ok
  end

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
  def set_menu(session, menu), do: GenServer.call(via_tuple(session), {:set_menu, menu})
  def get_menu(session), do: GenServer.call(via_tuple(session), {:get_menu})
  def get(session), do: GenServer.call(via_tuple(session), {:get})
  def next(session), do: GenServer.call(via_tuple(session), {:next})
  def previous(session), do: GenServer.call(via_tuple(session), {:previous})

  def sync(session), do: GenServer.call(via_tuple(session), {:previous})
  def add(session, data), do: GenServer.call(via_tuple(session), {:add, data})

  def handle_call({:get}, _from, state ) do
    %{ routes: routes } = state
    {:reply, routes, state}
  end

  def handle_call({:add, data }, _from, state ) when is_list(data) do
    new_state = Map.put(state, :routes, data)
    {:reply, data, new_state}
  end

  def handle_call({:add, data }, _from, state ) when is_map(data) do
    %{routes: routes} = state
    new_state = Map.put(state, :routes, [data | routes])
    {:reply, [data | routes], new_state}
  end

  def handle_call({:next}, _from, state) do
    %{ routes: routes } = state
    [head | tail ] = routes
    depth = head[:depth]
    new_head = Map.put(head, :depth, depth + 1)
    new_state = Map.put(state, :routes, [new_head | tail])
    {:reply, [new_head | tail], new_state}
  end

  def handle_call({:previous}, _from,  state ) do
    %{ routes: routes } = state
    [head | tail ] = routes
    depth = head[:depth]
    new_state = case depth do
      1 ->
        case tail do
          [] -> [%{depth: 1, value: "555"}]
          _ -> tail
        end
      _->
        new_head = Map.put(head, :depth, depth - 1)
        [new_head | tail]
    end
    {:reply, new_state, Map.put(state, :routes, new_state)}
  end

  def handle_call({:set_menu, menu }, _from, state ) do
    new_state = Map.put(state, :menu, menu)
    {:reply, new_state, new_state}
  end

  def handle_call({:get_menu}, _from, state ) do
    %{ menu: menu } = state
    {:reply, menu, state}
  end
end
