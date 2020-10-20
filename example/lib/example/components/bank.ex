alias Example.Domain.Client
alias Example.Components.Bank
alias Example.Components.ResetPin
alias Example.Components.Branch
alias Example.Components.Exit
alias ExUssd.Menu

defmodule Example.Components.Bank do

  def start_session do
    Menu.render(
        name: "Home",
        handler: fn menu, _api_parameters, _should_handle ->

          # Africa's talking api_parameters
          # %{
          #   networkCode: "safaricom",
          #   phoneNumber: "254722000000",
          #   serviceCode: "*544#",
          #   sessionId: "12246",
          #   text: "1"
          # }

          # Infobip api_parameters
          # %{
          #   countryName: "Kenya",
          #   imsi: "1r3456ry51",
          #   msisdn: "254722000000",
          #   networkName: "safaricom",
          #   shortCode: "*544#",
          #   text: "1"
          # }

          phone_number = "254722000000"

          client_name = Client.greet_client(phone_number: phone_number)

          menu
          |> Map.put(:title, "Dear #{client_name}, welcome to Bank Mobile Banking.\nPlease enter your PIN to continue. Forgot Pin ? Press 1")
          |> Map.put(:handle, true)
          |> Map.put(:validation_menu, Bank.bank_menu())
      end
    )
  end

  def bank_menu do
    Menu.render(
    name: "back_menu",
    handler: fn menu, api_parameters, should_handle ->
      case should_handle do
        true ->
          cond do
            api_parameters.text == "1" ->
              menu
              |> Map.put(:success, true)
              |> Map.put(:handle, true)
              |> Map.put(:title, "New PIN should should not match with the previous 5 PIN's. Please keep your debit card with you for PIN reset.\nPress 1 to continue.")
              |> Map.put(:validation_menu, ResetPin.forgot_pin())

            api_parameters.text == "5555" ->
              menu
                |> Map.put(:success, true)
                |> Map.put(:show_navigation, false)
                |> Map.put(:title, "select")
                |> Map.put(:menu_list,
                [
                  Branch.change_branch(),
                  Exit.exit_menu()
                ])
            true ->
              menu
              |> Map.put(:error, "Invalid PIN\n")
          end
        false -> menu
      end
    end)
  end

end
