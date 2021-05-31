defmodule UssdTest do
  use ExUnit.Case
  alias ScratchCard.Ussd

  describe "dial *141# " do
    menu = Ussd.start_session()

    assert ExUssd.goto(
             menu: menu,
             api_parameters: %{
               "service_code" => "*141#",
               "session_id" => "session_01",
               "text" => "*141#"
             }
           ) ==
             {:ok,
              %{
                menu_string:
                  "You have entered an incorrect format.\nPlease check and try again. For recharge dial *141*recharge voucher PIN# ok. Thank you.",
                should_close: true
              }}
  end

  describe "dial with incorrect voucher_number" do
    menu = Ussd.start_session()

    assert ExUssd.goto(
             menu: menu,
             api_parameters: %{
               "service_code" => "*141#",
               "session_id" => "session_01",
               "text" => "*141*1#"
             }
           ) ==
             {:ok,
              %{
                menu_string:
                  "Sorry we are unable to complete your request at the moment. Please try again later",
                should_close: true
              }}
  end

  describe "dial with valid voucher_number" do
    menu = Ussd.start_session()

    assert ExUssd.goto(
             menu: menu,
             api_parameters: %{
               "service_code" => "*141#",
               "session_id" => "session_01",
               "text" => "*141*123456789#"
             }
           ) ==
             {:ok, %{menu_string: "Recharge successful", should_close: true}}
  end
end
