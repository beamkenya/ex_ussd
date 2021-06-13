defmodule ExUssd.Op do
  alias ExUssd.{Utils, Registry, Ops, Display, Route, Error}
  require ExUssd.Utils

  @allowed_fields [
    :error,
    :title,
    :next,
    :previous,
    :should_close,
    :split,
    :delimiter_style,
    :continue,
    :default_error,
    :show_navigation,
    :data
  ]

  def new(fields) when is_list(fields),
    do: new(Enum.into(fields, %{data: Keyword.get(fields, :data)}))

  def new(%{name: name, handler: handler, data: data}) do
    args = %{
      name: name,
      handler: handler,
      data: data,
      validation_menu: {%ExUssd{name: "", handler: handler}, false}
    }

    struct(ExUssd, args)
  end

  def new(%{name: name, data: data}) do
    name = Utils.truncate(name, length: 145)
    new(%{name: name, handler: nil, data: data})
  end

  def add(%ExUssd{orientation: :vertical} = menu, %ExUssd{} = child) do
    {menu_list, _state} = Map.get(menu, :menu_list, {[], true})

    Map.merge(menu, %{menu_list: {[child | menu_list], true}})
  end

  def add(%ExUssd{orientation: :horizontal}, _child) do
    message = "the menu orientation is set to :vertical"
    raise Error, message: message
  end

  def dynamic(%ExUssd{} = menu, fields) when is_list(fields),
    do: dynamic(menu, Enum.into(fields, %{}))

  def dynamic(menu, %{menus: menus, handler: handler, orientation: :vertical})
      when menus != [] do
    menu_list =
      Enum.map(menus, fn menu ->
        Map.merge(menu, %{handler: handler})
      end)

    Map.merge(menu, %{menu_list: {Enum.reverse(menu_list), true}})
  end

  def dynamic(_, %{menus: menus, orientation: :vertical}) when menus != [] do
    message = "vertical menus: Handler not provided"
    raise Error, message: message
  end

  def dynamic(%ExUssd{menu_list: {[], _}} = menu, %{
        menus: menus,
        orientation: :horizontal
      })
      when menus != [] do
    Map.merge(menu, %{menu_list: {menus, true}, orientation: :horizontal})
  end

  def dynamic(_menu, %{menus: _menus, orientation: :horizontal}) do
    message = "the menu orientation is set to :vertical, comment out `ExUssd.add/2`"
    raise Error, message: message
  end

  def dynamic(_menu, %{menus: menus, orientation: _}) when menus == [] do
    message = "menus Cannot to an empty list"
    raise Error, message: message
  end

  def dynamic(_menu, %{menus: menus, orientation: _}) when not is_list(menus) do
    message = "menus should be a list of %ExUssd{} found #{menus}"
    raise Error, message: message
  end

  def navigate(%ExUssd{} = menu, fields) when is_list(fields),
    do: navigate(menu, Enum.into(fields, %{data: Keyword.get(fields, :data)}))

  def navigate(%ExUssd{data: data} = menu, %{handler: handler}) when not is_nil(data) do
    get_menu(menu, handler, data)
  end

  def navigate(%ExUssd{} = menu, %{handler: handler, data: data}) do
    get_menu(menu, handler, data)
  end

  defp get_menu(menu, handler, data) do
    args =
      menu
      |> Map.from_struct()
      |> Map.take(@allowed_fields)
      |> Map.merge(%{parent: menu.parent, data: data, handler: handler, name: ""})

    validation_menu = struct(ExUssd, args)

    menu = ExUssd.set(menu, data: data)

    handler =
      if function_exported?(menu.handler, :after_route, 1), do: menu.handler, else: handler

    Map.merge(menu, %{
      handler: handler,
      validation_menu: {validation_menu, true}
    })
  end

  def set(%ExUssd{data: nil} = menu, [data: _data] = field) do
    Map.merge(menu, Enum.into(field, %{}, fn {k, v} -> {k, v} end))
  end

  def set(%ExUssd{data: data} = menu, [data: _data] = field) do
    Map.merge(menu, Enum.into(field, %{}, fn {k, v} -> {k, Map.merge(data, v)} end))
  end

  def set(%ExUssd{} = menu, fields) do
    if MapSet.subset?(MapSet.new(Keyword.keys(fields)), MapSet.new(@allowed_fields)) do
      Map.merge(menu, Enum.into(fields, %{}, fn {k, v} -> {k, {v, true}} end))
    else
      raise Error,
        message:
          "Expected field allowable fields #{inspect(@allowed_fields)} found #{
            inspect(Keyword.keys(fields))
          }"
    end
  end

  def end_session(session_id: session_id) do
    Registry.stop(session_id)
  end

  defp loop(menu, %{session_id: session_id} = api_parameters, route) do
    case Registry.lookup(session_id) do
      {:error, :not_found} ->
        Registry.start(session_id)
        Registry.add(session_id, route)

        current_menu =
          case Ops.circle(Enum.reverse(route), menu, api_parameters) do
            {:error, current_menu} ->
              apply_effect(current_menu, menu, api_parameters)

            current_menu ->
              current_menu
          end

        Registry.set_current(session_id, current_menu)
        current_menu

      {:ok, _pid} ->
        {_, current_menu} = Registry.get_current(session_id)
        current_menu = Ops.circle(route, current_menu, api_parameters, menu)
        Registry.set_current(session_id, current_menu)
        current_menu
    end
  end

  defp apply_effect(current_menu, menu, api_parameters) do
    if function_exported?(menu.handler, :after_route, 1) do
      menu =
        menu
        |> Utils.invoke_after_route({:error, api_parameters})
        |> get_in([Access.key(:validation_menu), Access.elem(0)])

      route =
        Route.get_route(%{
          text: api_parameters.text,
          service_code: api_parameters.service_code
        })

      Ops.circle(Enum.reverse(route), menu, api_parameters)
    else
      {:ok, current_menu}
    end
  end

  def goto(fields) when is_list(fields),
    do: goto(Enum.into(fields, %{}))

  def goto(%{
        api_parameters:
          %{"text" => text, "session_id" => session_id, "service_code" => service_code} =
            api_parameters,
        menu: menu
      }) do
    api_parameters = Utils.format_map(api_parameters)

    route = Route.get_route(%{text: text, service_code: service_code, session_id: session_id})

    {_, current_menu} = loop(menu, api_parameters, route)

    Display.new(
      menu: current_menu,
      routes: Registry.get(session_id),
      api_parameters: api_parameters
    )
  end

  def goto(%{
        api_parameters: %{text: text, session_id: session_id, service_code: service_code},
        menu: menu
      }) do
    api_parameters = %{
      "text" => text,
      "session_id" => session_id,
      "service_code" => service_code
    }

    goto(%{api_parameters: api_parameters, menu: menu})
  end

  def goto(%{api_parameters: %{"session_id" => _, "service_code" => _} = api_parameters, menu: _}) do
    message = "'text' not found in api_parameters #{inspect(api_parameters)}"
    raise Error, message: message
  end

  def goto(%{api_parameters: %{"text" => _, "service_code" => _} = api_parameters, menu: _}) do
    message = "'session_id' not found in api_parameters #{inspect(api_parameters)}"
    raise Error, message: message
  end

  def goto(%{api_parameters: %{"text" => _, "session_id" => _} = api_parameters, menu: _}) do
    message = "'service_code' not found in api_parameters #{inspect(api_parameters)}"
    raise Error, message: message
  end

  def goto(%{api_parameters: api_parameters, menu: _}) do
    message =
      "'text', 'service_code', 'session_id',  not found in api_parameters #{
        inspect(api_parameters)
      }"

    raise Error, message: message
  end
end
