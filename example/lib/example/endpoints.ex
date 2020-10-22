alias Example.Components.Bank

defmodule Example.Endpoints do
  use Plug.Router

  require Logger

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["text/*"],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)
  # Africa talking callback URL
  post "africa-talking/ussd" do
    request = conn.params
    IO.inspect request
    %{"text" => text, "sessionId" => session_id, "serviceCode" => service_code} = request

    menu = Bank.start_session()

    {:ok, response} =
      ExUssd.goto(
        internal_routing: %{text: text, session_id: session_id, service_code: service_code},
        menu: menu,
        api_parameters: request
      )

    send_resp(conn, 200, response)
  end

  # Infobip callback URL's
  post "ussd/session/:session_id/start" do
    request = conn.body_params

    %{"shortCode" => service_code, "text" => text} = request

    menu = Bank.start_session()

    {:ok, response} =
      ExUssd.goto(
        internal_routing: %{text: text, session_id: session_id, service_code: service_code},
        menu: menu,
        api_parameters: request
      )

    render_json(conn, response)
  end

  put "ussd/session/:session_id/response" do
    request = conn.body_params

    %{"shortCode" => service_code, "text" => text} = request

    menu = ExUssd.get_menu(session_id: session_id)

    {:ok, response} =
      ExUssd.goto(
        internal_routing: %{text: text, session_id: session_id, service_code: service_code},
        menu: menu,
        api_parameters: request
      )

    render_json(conn, response)
  end

  put "ussd/session/:session_id/end" do
    ExUssd.end_session(session_id)

    response = %{
      responseExitCode: 200,
      responseMessage: ""
    }

    render_json(conn, response)
  end

  match(_, do: send_resp(conn, 404, "404 error not found"))

  defp render_json(%{status: status} = conn, data) do
    body = Jason.encode!(data)
    send_resp(conn, status || 200, body)
  end
end
