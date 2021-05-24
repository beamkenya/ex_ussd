defmodule App.Endpoints do
  use Plug.Router

  alias App.Ussd

  require Logger

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["text/*"],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  # Africa talking callback URL
  post "v1/ussd" do
    request = conn.params

    %{"text" => text, "sessionId" => session_id, "serviceCode" => service_code} = request
    menu = Ussd.start_session()

    response =
      ExUssd.goto(
        menu: menu,
        api_parameters: %{
          "service_code" => service_code,
          "session_id" => session_id,
          "text" => text
        }
      )
      |> case do
        {:ok, %{menu_string: menu_string, should_close: false}} ->
          "CON " <> menu_string

        {:ok, %{menu_string: menu_string, should_close: true}} ->
          # End Session
          ExUssd.end_session(session_id: session_id)

          "END " <> menu_string
      end

    send_resp(conn, 200, response)
  end

  match(_, do: send_resp(conn, 404, "404 error not found"))
end
