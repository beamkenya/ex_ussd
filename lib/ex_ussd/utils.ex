defmodule ExUssd.Utils do
  @moduledoc """
  This module contains utils helpers for `ExUssd`.
  """

  @default_value 436_739_010_658_356_127_157_159_114_145

  def to_int({0, _}, menu, input_value), do: to_int({@default_value, ""}, menu, input_value)

  def to_int({value, ""}, %ExUssd{nav: nav}, input_value) do
    %ExUssd.Nav{match: next, show: show_next} = Enum.find(nav, &(&1.type == :next))
    %ExUssd.Nav{match: home, show: show_home} = Enum.find(nav, &(&1.type == :home))
    %ExUssd.Nav{match: back, show: show_back} = Enum.find(nav, &(&1.type == :back))

    case input_value do
      v when v == next and show_next ->
        605_356_150_351_840_375_921_999_017_933

      v when v == back and show_back ->
        128_977_754_852_657_127_041_634_246_588

      v when v == home and show_home ->
        705_897_792_423_629_962_208_442_626_284

      _ ->
        value
    end
  end

  def to_int(:error, _menu, _input_value), do: @default_value

  def to_int({_value, _}, _menu, _input_value), do: @default_value

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
end
