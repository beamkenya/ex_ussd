defmodule ExUssd.Registry do
  use GenServer
  def init(_opts), do: {:ok, %{routes: [], home: nil, current: nil}}

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

  def get(session), do: GenServer.call(via_tuple(session), {:get})
  def next(session), do: GenServer.call(via_tuple(session), {:next})
  def previous(session), do: GenServer.call(via_tuple(session), {:previous})
  def get_current(session), do: GenServer.call(via_tuple(session), {:get_current})
  def get_home(session), do: GenServer.call(via_tuple(session), {:get_home})

  def depth(session, depth), do: GenServer.call(via_tuple(session), {:depth, depth})
  def add(session, route), do: GenServer.call(via_tuple(session), {:add, route})
  def set(session, route), do: GenServer.call(via_tuple(session), {:set, route})

  def set_home(session, menu),
    do: GenServer.call(via_tuple(session), {:set_home, menu})

  def set_current(session, menu),
    do: GenServer.call(via_tuple(session), {:set_current, menu})

  def handle_call({:get}, _from, state) do
    %{routes: routes} = state
    {:reply, routes, state}
  end

  def handle_call({:get_current}, _from, state) do
    %{current: menu} = state
    {:reply, menu, state}
  end

  def handle_call({:get_home}, _from, state) do
    %{home_menu: home_menu} = state
    {:reply, home_menu, state}
  end

  def handle_call({:next}, _from, state) do
    %{routes: routes} = state
    [head | tail] = routes
    depth = head[:depth]
    new_head = Map.put(head, :depth, depth + 1)
    new_state = Map.put(state, :routes, [new_head | tail])
    {:reply, [new_head | tail], new_state}
  end

  def handle_call({:depth, depth}, _from, state) do
    %{routes: routes} = state
    [head | tail] = routes
    new_head = Map.put(head, :depth, depth)
    new_state = Map.put(state, :routes, [new_head | tail])
    {:reply, [new_head | tail], new_state}
  end

  def handle_call({:previous}, _from, state) do
    %{routes: routes} = state
    [head | tail] = routes
    depth = head[:depth]

    case depth do
      1 ->
        new_state =
          case tail do
            [] -> [%{depth: 1, value: "555"}]
            _ -> tail
          end

        {:reply, routes, Map.put(state, :routes, new_state)}

      _ ->
        new_head = Map.put(head, :depth, depth - 1)
        new_state = [new_head | tail]
        {:reply, routes, Map.put(state, :routes, new_state)}
    end
  end

  def handle_call({:set_home, menu}, _from, state) do
    {:reply, menu, Map.put(state, :home, menu)}
  end

  def handle_call({:set_current, menu}, _from, state) do
    {:reply, menu, Map.put(state, :current, menu)}
  end

  def handle_call({:add, route}, _from, state) when is_list(route) do
    new_state = Map.put(state, :routes, route)
    {:reply, route, new_state}
  end

  def handle_call({:add, route}, _from, state) when is_map(route) do
    %{routes: routes} = state
    new_state = Map.put(state, :routes, [route | routes])
    {:reply, [route | routes], new_state}
  end

  def handle_call({:set, route}, _from, state) when is_map(route) do
    new_state = Map.put(state, :routes, [route])
    {:reply, [route], new_state}
  end

  def handle_call({:set, route}, _from, state) when is_list(route) do
    new_state = Map.put(state, :routes, route)
    {:reply, route, new_state}
  end
end
