defmodule ExUssd.Menu do
  defstruct name: nil,
            callback: nil,
            handler: nil,
            title: nil,
            menu_list: [],
            error: nil,
            handle: false,
            success: false,
            show_options: true,
            next: "98",
            previous: "0",
            split: 7,
            should_close: false,
            display_style: ":",
            parent: nil,
            validation_menu: nil,
            show_navigation: true,
            default_error_message: "Invalid Choice\n"

  @doc """
    Render Function is used to create a ussd Menu.

    ## Params
  The function requires two keys as parameters
    `:name` - Name of the ussd component
    `:handler` - a callback handler that is invoked when then route is at that current position.
    The callback handler receives %ExUssd.Menu{} and the ussd api_parameters

    Returns %ExUssd.Menu{} .

    ## Examples
        iex> ExUssd.Menu.render(
        ...>  name: "Home",
        ...>  handler: fn menu, _api_parameters ->
        ...>    menu |> Map.put(:title, "Home Page: Welcome")
        ...>  end
        ...> )
        %ExUssd.Menu{
          callback: #Function<1.49663807/1 in ExUssd.Menu.render/1>,
          error: nil,
          handle: false,
          handler: #Function<43.97283095/2 in :erl_eval.expr/5>,
          menu_list: [],
          name: "Home",
          next: "98",
          previous: "0",
          should_close: false,
          show_options: true,
          split: 7,
          success: false,
          title: nil
        }
  """

  def render(name: name, handler: handler) do
    %ExUssd.Menu{
      name: name,
      handler: handler,
      callback: fn api_parameters, should_handle ->
        handle(%ExUssd.Menu{name: name, handler: handler}, api_parameters, should_handle)
      end
    }
  end

  defp handle(menu, api_parameters, should_handle) do
    menu.handler.(menu, api_parameters, should_handle)
  end
end
