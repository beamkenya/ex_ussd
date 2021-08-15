defmodule ExUssd.Route do
  @moduledoc """
    Route for USSD session.
  """

  alias __MODULE__
  alias ExUssd.Registry

  @type t :: %__MODULE__{
          mode: term(),
          route: list() | map()
        }
  defstruct [:route, mode: :serial]

  defmodule State do
    @moduledoc """
    Route value struct
    """
    @behaviour Access

    # https://gist.github.com/andykingking/4982353b8c69ea301c698e97f6d34635
    # Structs by default do not implement this. It's easy to delegate this to the Map implementation however.
    defdelegate get(coin, key, default), to: Map
    defdelegate fetch(coin, key), to: Map
    defdelegate get_and_update(coin, key, func), to: Map
    defdelegate pop(coin, key), to: Map

    defstruct [:depth, :text, attempt: %{count: 0, inputs: []}]
  end

  @doc """
    Initialize the route.
    
    ## Parameters
    - `opts` - contains text string and the USSD service code.

     ## Examples
      iex> ExUssd.Route.get_route(%{text: "", service_code: "*544#"})
      %Route{mode: :parallel, route: [%{depth: 1, text: "555"}]}

      iex> ExUssd.Route.get_route(%{text: "2", service_code: "*544#"})
      %Route{mode: :serial, route: %{depth: 1, text: "2"}}

      iex> ExUssd.Route.get_route(%{text: "*544*2*3#", service_code: "*544#"})
      %Route{mode: :parallel, route: [%{depth: 1, text: "3"}, %{depth: 1, text: "2"}, %{depth: 1, text: "555"}]}
  """

  @spec get_route(%{text: String.t(), session_id: String.t(), service_code: String.t()}) ::
          Route.t()
  def get_route(%{text: text, service_code: service_code} = opts) do
    text = String.replace(text, "#", "")

    service_code = String.replace(service_code, "#", "")

    session = Map.get(opts, :session_id, "#{System.unique_integer()}")

    mode =
      case Registry.lookup(session) do
        {:error, :not_found} -> :parallel
        _ -> :serial
      end

    opts =
      Map.merge(opts, %{
        mode: mode,
        text: text,
        service_code: service_code,
        equivalent: String.equivalent?(text, service_code),
        contains: String.contains?(text, service_code),
        text_list: String.split(text, "*")
      })

    fun = fn
      %{text: _text, mode: :parallel, equivalent: true, contains: true} ->
        %Route{mode: :parallel, route: [%State{depth: 1, text: "555"}]}

      %{text: text, mode: :parallel, equivalent: false, contains: false} ->
        list = String.split(text, "*")

        route = Enum.reduce(list, [%State{depth: 1, text: "555"}], &reduce_route/2)

        %Route{mode: :parallel, route: route}

      %{mode: :parallel, service_code: code, equivalent: false, contains: true, text_list: list} ->
        list = list -- String.split(code, "*")

        route =
          Enum.reduce(list, [%State{depth: 1, text: "555"}], fn text, acc ->
            [%State{depth: 1, text: text} | acc]
          end)

        %Route{mode: :parallel, route: route}

      %{text: text, mode: :serial, equivalent: false, contains: false, text_list: [_ | []]} ->
        %Route{route: %State{depth: 1, text: text}}

      %{text: _text, mode: :serial, text_list: text_list} ->
        %Route{route: %State{depth: 1, text: List.last(text_list)}}
    end

    apply(fun, [opts])
  end

  @spec reduce_route(String.t(), list(Route.t())) :: list(Route.t())
  defp reduce_route(text, acc) do
    if String.equivalent?(text, "") do
      acc
    else
      [%State{depth: 1, text: text} | acc]
    end
  end
end
