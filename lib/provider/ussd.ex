defmodule ExUssd.Ussd do
  @typedoc "Menu Struct"
  @type menu() :: ExUssd.Menu.t()
  @typedoc """
  A map value carrying api parameters, e.g
  %{
   sessionId: "session_01",
   phoneNumber: "254722000000",
   networkCode: "Safaricom",
   serviceCode: "*544#",
   text: "1"
  }
  """
  @type api_parameters() :: map()
  @typedoc """
  An internal routing map that takes text value, session id and service code, e.g.
  %{text: "1", session_id: "session_01", service_code: "*544#"}
  """

  @type internal_routing() :: %{
          text: String.t(),
          session_id: String.t(),
          service_code: String.t()
        }

  @callback goto(
              internal_routing: internal_routing(),
              menu: menu(),
              api_parameters: api_parameters()
            ) :: any()
end
