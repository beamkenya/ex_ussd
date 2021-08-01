defmodule ExUssd.Executer do
  @moduledoc """
  This module provides the executer for the USSD lib.
  """

  def execute(%ExUssd{resolve: resolve} = menu, api_parameters, metadata)
      when is_function(resolve) do
    if is_function(resolve, 3) do
      apply(resolve, [menu, api_parameters, metadata])
    else
      raise %BadArityError{function: resolve, args: [menu, api_parameters, metadata]}
    end
  end
end
