defmodule ExUssd.Executer do
  @moduledoc """
  This module provides the executer for the USSD lib.
  """

  def execute(%ExUssd{resolve: resolve} = menu, api_parameters, metadata) do
    cond do
      is_function(resolve, 3) ->
        apply(resolve, [menu, api_parameters, metadata])
    end
  end
end
