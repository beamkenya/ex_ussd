defmodule ExUssd.Route do
  defstruct mode: :serial, route: []

  @moduledoc """
    Route for USSD session.
  """
  alias __MODULE__
  alias ExUssd.Registry

  @doc """
    Initialize the route.
    
     ## Examples
      iex> ExUssd.Route.get_route(%{text: "*544#", service_code: "*544#"})
      %Route{mode: :serial, route: [%{depth: 1, text: "555"}]}

      iex> ExUssd.Route.get_route(%{text: "*544*2*3#", service_code: "*544#"})
      %Route{mode: :parallel, route: [%{depth: 1, text: "3"}, %{depth: 1, text: "2"}, %{depth: 1, text: "555"}]}
  """

  def get_route(%{text: text, service_code: service_code} = opts) do
    text = String.replace(text, "#", "")

    service_code = String.replace(service_code, "#", "")

    session = Map.get(opts, :session, "#{System.unique_integer()}")

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
        %Route{mode: :parallel, route: [%{depth: 1, value: "555"}]}

      %{text: text, mode: :parallel, equivalent: false, contains: false} ->
        list = String.split(text, "*")

        route =
          Enum.reduce(list, [%{depth: 1, value: "555"}], fn value, acc ->
            if String.equivalent?(value, "") do
              acc
            else
              [%{depth: 1, value: value} | acc]
            end
          end)

        %Route{mode: :parallel, route: route}

      %{mode: :parallel, service_code: code, equivalent: false, contains: true, text_list: list} ->
        list = list -- String.split(code, "*")

        route =
          Enum.reduce(list, [%{depth: 1, value: "555"}], fn value, acc ->
            [%{depth: 1, value: value} | acc]
          end)

        %Route{mode: :parallel, route: route}

      %{text: text, mode: :serial, equivalent: false, contains: false, text_list: [_ | []]} ->
        %Route{route: %{depth: 1, value: text}}

      %{text: _text, mode: :serial, text_list: text_list} ->
        %Route{route: %{depth: 1, value: List.last(text_list)}}
    end

    apply(fun, [opts])
  end
end
