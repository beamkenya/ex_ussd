alias ExUssd.Menu
alias Example.Domain.Client
alias Example.Components.ResetPin

defmodule Example.Components.ResetPin do
  def forgot_pin do
    Menu.render(
      name: "Forgot Pin",
      handler: fn menu, api_parameters, should_handle ->
        case should_handle do
          true ->
            cond do
              api_parameters.text == "1" ->
                menu
                |> Map.put(:success, true)
                |> Map.put(:handle, true)
                |> Map.put(:show_navigation, false)
                |> Map.put(:title, "Enter new PIN")
                |> Map.put(:validation_menu, ResetPin.set_new_pin())

              true ->
                menu
                |> Map.put(:error, "Invalid Option\n")
            end

          false ->
            menu
        end
      end
    )
  end

  def set_new_pin do
    Menu.render(
      name: "set new pin",
      handler: fn menu, api_parameters, should_handle ->
        case should_handle do
          true ->
            cond do
              String.length(api_parameters.text) == 4 ->
                case Client.reset_pin(pin: api_parameters.text) do
                  {:ok, _} ->
                    menu
                    |> Map.put(:title, "Successful PIN reset.")
                    |> Map.put(:success, true)
                    |> Map.put(:should_close, true)

                  {:error, _} ->
                    menu
                    |> Map.put(
                      :title,
                      "Error occurred, try later, or call our customer care for assistance."
                    )
                    |> Map.put(:success, true)
                    |> Map.put(:should_close, true)
                end

              true ->
                menu
                |> Map.put(:error, "PIN should be 4 digits\n")

              false ->
                menu
            end
        end
      end
    )
  end
end
