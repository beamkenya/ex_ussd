defmodule ScratchCard.Ussd.ProcessCardHandler do
  use ExUssd.Handler

  def init(%{data: %{voucher_number: voucher_number}} = menu, _api_parameters) do
    case process_voucher_validity(voucher_number) do
      {:ok, _} ->
        menu
        |> ExUssd.set(title: "Recharge successful")
        |> ExUssd.set(should_close: true)

      {:error, _} ->
        menu
        |> ExUssd.set(
          title:
            "Sorry we are unable to complete your request at the moment. Please try again later"
        )
        |> ExUssd.set(should_close: true)
    end
  end

  def process_voucher_validity(voucher_number) do
    if voucher_number == 123_456_789 do
      {:ok, "recharge_successful"}
    else
      case String.length("#{voucher_number}") != 9 do
        true -> {:error, "invalid card"}
        _ -> {:error, "expired card"}
      end
    end
  end
end
