defmodule EqutelGW do
  import SweetXml

  @doc """
  convert xml_to_map
  ## Example
      iex> xml = "<USSDDynMenuRequest><requestId>$requestId</requestId><msisdn>$msisdn</msisdn><timeStamp>2018/01/24 08:23:28</timeStamp><starCode>*123#</starCode><keyWord>nhif</keyWord><dataSet><param><id>CIRCLEID</id><value>1</value></param><param><id>CIRCLE_ID</id><value>1</value></param><param><id>DIAL-CODE</id><value>*123#</value></param><param><id>SESSION_ID</id><value>$session_ID</value></param><param><id>TRAVERSAL-PATH</id><value>123</value></param></dataSet><userData>*123#</userData></USSDDynMenuRequest>"
      iex> EqutelGW.xml_to_map(xml_request: xml)
      %{
        "CIRCLEID" => "1",
        "CIRCLE_ID" => "1",
        "DIAL-CODE" => "*123#",
        "SESSION_ID" => "$session_ID",
        "TRAVERSAL-PATH" => "123",
        "keyWord" => "nhif",
        "msisdn" => "$msisdn",
        "requestId" => "$requestId",
        "starCode" => "*123#",
        "text" => "*123#",
        "timeStamp" => "2018/01/24 08:23:28"
      }
  """

  def xml_to_map(xml_request: xml) do
    xml_request = xml |> String.trim() |> String.split(~r{\n  *}, trim: true) |> Enum.join("")

    request_id = xml_request |> xpath(~x"//requestId/text()")
    msisdn = xml_request |> xpath(~x"//msisdn/text()")
    timeStamp = xml_request |> xpath(~x"//timeStamp/text()")
    starCode = xml_request |> xpath(~x"//starCode/text()")
    keyWord = xml_request |> xpath(~x"//keyWord/text()")
    userData = xml_request |> xpath(~x"//userData/text()")

    %{keys: keys, values: values} =
      xml_request
      |> xpath(~x"//dataSet", keys: ~x".//param/id/text()"sl, values: ~x".//param/value/text()"sl)

    data = Enum.zip(keys, values) |> Enum.into(%{})

    data
    |> Map.put_new("requestId", "#{request_id}")
    |> Map.put_new("msisdn", "#{msisdn}")
    |> Map.put_new("timeStamp", "#{timeStamp}")
    |> Map.put_new("starCode", "#{starCode}")
    |> Map.put_new("keyWord", "#{keyWord}")
    |> Map.put_new("text", "#{userData}")
  end

  @doc """
  convert map_to_xml
  ## Example
      iex> response = %{
      ...>  msisdn: "254729363838",
      ...>  requestId: "requestId",
      ...>  starCode: "*544#",
      ...>  should_close: false,
      ...>  menu_string: "",
      ...>  routes: [%{depth: 1, value: "555"}],
      ...>  current_menu: %{title: ""},
      ...>  url: "http://0.0.0.0"
      ...>}
      iex> import SweetXml
      iex> xml = EqutelGW.map_to_xml(response)
      iex> request_id = xml |> xpath(~x"//requestId/text()"s)
      "requestId"
  """
  def map_to_xml(response) do
    %{
      msisdn: msisdn,
      requestId: requestId,
      starCode: starCode,
      should_close: should_close,
      menu_string: menu_string,
      routes: routes,
      current_menu: current_menu,
      url: url
    } = response

    rspFlag = unless should_close, do: 1, else: 2

    rspTag =
      case is_bitstring(current_menu.title) do
        true -> current_menu.title
        _ -> ""
      end

    id = length(routes)
    now = NaiveDateTime.add(NaiveDateTime.utc_now(), 3600 * 3) |> NaiveDateTime.truncate(:second)
    time = "#{now}" |> String.split(" ") |> tl |> hd
    date_string = "#{now.year}/#{now.month}/#{now.day} #{time}"
    xml = "<USSDDynMenuResponse>
      <requestId>#{requestId}</requestId>
      <msisdn>#{msisdn}</msisdn>
      <starCode>#{starCode}</starCode>
      <langId>1</langId>
      <encodingScheme>0</encodingScheme>
      <dataSet>
      <param>
        <id>#{id}</id>
        <value>#{menu_string}</value>
        <rspFlag>#{rspFlag}</rspFlag>
        <rspTag>#{rspTag}</rspTag>
        <rspURL>#{url}</rspURL>
        <appendIndex>0</appendIndex>
        <default>1</default>
      </param>
      </dataSet>
      <ErrCode>1</ErrCode>
      <errURL>#{url}/errcallback</errURL>
      <timeStamp>#{date_string}</timeStamp>
    </USSDDynMenuResponse>
    "
    xml |> String.trim() |> String.split(~r{\n  *}, trim: true) |> Enum.join("")
  end
end
