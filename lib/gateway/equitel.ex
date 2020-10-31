defmodule EqutelGW do
  import SweetXml

  def xml_to_map(xml_request: xml) do
    xml_request = xml |> String.trim() |> String.split(~r{\n  *}, trim: true) |> Enum.join("")

    # "<USSDDynMenuRequest><requestId>$requestId</requestId><msisdn>$msisdn</msisdn><timeStamp>2018/01/24 08:23:28</timeStamp><starCode>*123#</starCode><keyWord>nhif</keyWord><dataSet><param><id>CIRCLEID</id><value>1</value></param><param><id>CIRCLE_ID</id><value>1</value></param><param><id>DIAL-CODE</id><value>*123#</value></param><param><id>SESSION_ID</id><value>$session_ID</value></param><param><id>TRAVERSAL-PATH</id><value>123</value></param></dataSet><userData>*123#</userData></USSDDynMenuRequest>"
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
    "<USSDDynMenuResponse>
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
  end
end
