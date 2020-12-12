defmodule ExUssd.State.Registry do
  use GenServer
  def init(_opts), do: {:ok, %{routes: [], current_menu: nil, home_menu: nil}}

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

  def set_current_menu(session, current_menu),
    do: GenServer.call(via_tuple(session), {:set_current_menu, current_menu})

  def set_home_menu(session, home_menu),
    do: GenServer.call(via_tuple(session), {:set_home_menu, home_menu})

  def get_menu(session), do: GenServer.call(via_tuple(session), {:get_menu})

  def get_current_menu(session), do: GenServer.call(via_tuple(session), {:get_current_menu})

  def get_home_menu(session), do: GenServer.call(via_tuple(session), {:get_home_menu})

  def get(session), do: GenServer.call(via_tuple(session), {:get})
  def next(session), do: GenServer.call(via_tuple(session), {:next})
  def previous(session), do: GenServer.call(via_tuple(session), {:previous})
  def add(session, data), do: GenServer.call(via_tuple(session), {:add, data})

  def set(session, data), do: GenServer.call(via_tuple(session), {:set, data})

  def handle_call({:get}, _from, state) do
    %{routes: routes} = state
    {:reply, routes, state}
  end

  def handle_call({:add, data}, _from, state) when is_list(data) do
    new_state = Map.put(state, :routes, data)
    {:reply, data, new_state}
  end

  def handle_call({:add, data}, _from, state) when is_map(data) do
    %{routes: routes} = state
    new_state = Map.put(state, :routes, [data | routes])
    {:reply, [data | routes], new_state}
  end

  def handle_call({:set, data}, _from, state) when is_map(data) do
    new_state = Map.put(state, :routes, [data])
    {:reply, [data], new_state}
  end

  def handle_call({:next}, _from, state) do
    %{routes: routes} = state
    [head | tail] = routes
    depth = head[:depth]
    new_head = Map.put(head, :depth, depth + 1)
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

  def handle_call({:set_menu, menu}, _from, state) do
    new_state = Map.put(state, :menu, menu)
    {:reply, new_state, new_state}
  end

  def handle_call({:set_current_menu, current_menu}, _from, state) do
    new_state = Map.put(state, :current_menu, current_menu)
    %{current_menu: current_menu} = new_state
    {:reply, current_menu, new_state}
  end

  def handle_call({:set_home_menu, home_menu}, _from, state) do
    new_state = Map.put(state, :home_menu, home_menu)
    %{home_menu: home_menu} = new_state
    {:reply, home_menu, new_state}
  end

  def handle_call({:get_menu}, _from, state) do
    %{menu: menu} = state
    {:reply, menu, state}
  end

  def handle_call({:get_current_menu}, _from, state) do
    %{current_menu: current_menu} = state
    {:reply, current_menu, state}
  end

  def handle_call({:get_home_menu}, _from, state) do
    %{home_menu: home_menu} = state
    {:reply, home_menu, state}
  end
end
