defmodule Example.Domain.Client do
  def greet_client(phone_number: _phone_number) do
    # extract client name from the database (phone_number)
    "John"
  end

  def reset_pin(pin: _pin) do
    {:ok, "success"}
  end
end
