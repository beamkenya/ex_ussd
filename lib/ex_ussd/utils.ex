defmodule ExUssd.Utils do
  @moduledoc """
  This module contains utils helpers for `ExUssd`.
  """

  @default_value 436_739_010_658_356_127_157_159_114_145

  @spec to_int(term() | {integer(), String.t()}, ExUssd.t(), map(), String.t()) :: integer()
  def to_int(input, menu, _, input_value)

  def to_int({0, _}, menu, api_parameters, input_value),
    do: to_int({@default_value, ""}, menu, api_parameters, input_value)

  def to_int(
        {value, ""},
        %ExUssd{split: split, nav: nav, menu_list: menu_list},
        %{session_id: session},
        input_value
      ) do
    %ExUssd.Nav{match: next, show: show_next} = Enum.find(nav, &(&1.type == :next))
    %ExUssd.Nav{match: home, show: show_home} = Enum.find(nav, &(&1.type == :home))
    %ExUssd.Nav{match: back, show: show_back} = Enum.find(nav, &(&1.type == :back))

    %{depth: depth} =
      session
      |> ExUssd.Registry.fetch_route()
      |> List.first()

    # 1 * 7
    position = depth * split

    element = Enum.at(menu_list, position)

    case input_value do
      v when v == next and show_next and not is_nil(element) ->
        605_356_150_351_840_375_921_999_017_933

      v when v == back and show_back ->
        128_977_754_852_657_127_041_634_246_588

      v when v == home and show_home ->
        705_897_792_423_629_962_208_442_626_284

      _ ->
        value
    end
  end

  def to_int(:error, _menu, _, _input_value), do: @default_value

  @spec truncate(String.t(), keyword()) :: String.t()
  def truncate(text, options \\ []) do
    len = options[:length] || 30
    omi = options[:omission] || "..."

    cond do
      !String.valid?(text) ->
        text

      String.length(text) < len ->
        text

      true ->
        stop = len - String.length(omi)

        "#{String.slice(text, 0, stop)}#{omi}"
    end
  end

  @spec format(map()) :: map()
  def format(api_parameters) do
    Map.new(api_parameters, fn {key, val} ->
      try do
        {String.to_existing_atom(key), val}
      rescue
        _e in ArgumentError ->
          {String.to_atom(key), val}
      end
    end)
  end

  @spec fetch_metadata(map()) :: map()
  def fetch_metadata(%{session_id: session, service_code: service_code, text: text}) do
    %{route: [%{attempt: attempt} | _] = routes} = ExUssd.Registry.fetch_state(session)

    routes_string =
      routes
      |> Enum.reverse()
      |> get_in([Access.all(), Access.key(:text)])
      |> tl()
      |> Enum.join("*")

    service_code = String.replace(service_code, "#", "")

    routes_string =
      if(String.equivalent?(routes_string, ""),
        do: IO.iodata_to_binary([service_code, "#"]),
        else: IO.iodata_to_binary([service_code, "*", routes_string, "#"])
      )

    invoked_at = DateTime.truncate(DateTime.utc_now(), :second)
    %{attempt: attempt, invoked_at: invoked_at, route: routes_string, text: text}
  end
end
