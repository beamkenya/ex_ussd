defmodule ScratchCard.Ussd.HomeHandler do
  use ExUssd.Handler
  alias ScratchCard.Ussd.ProcessCardHandler

  def init(menu, _api_parameters) do
    menu
    |> ExUssd.set(
      title:
        "You have entered an incorrect format.\nPlease check and try again. For recharge dial *141*recharge voucher PIN# ok. Thank you."
    )
    |> ExUssd.set(should_close: true)
  end

  def callback(menu, api_parameters) do
    case api_parameters.text |> Integer.parse() do
      {voucher_number, _} ->
        menu
        |> ExUssd.navigate(data: %{voucher_number: voucher_number}, handler: ProcessCardHandler)
        |> ExUssd.set(continue: true)

      _ ->
        menu
        |> ExUssd.set(continue: false)
    end
  end
end
