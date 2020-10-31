defmodule ExUssd.Menu do
  @moduledoc """
  This struct enables USSD customization by modifying its fields.
  """
  @typedoc """
   - `name`: (Public) This is the value display when Menu is rendered as menu_list. check more on `menu_list`,
   - `handler`: (Public) A callback that modifies the current menu struct. Implemented via ExUssd.Handler
   - `callback`: (Internal) A callback function that takes the `handler` callback. This function is triggered when the client is at that menu position.
   - `title`: (Public) Outputs the ussd's title,
   - `menu_list`: (Public) Takes a list of Ussd Menu struct,
   - `error`: (Public) A custom validation error message for `validation_menu`,
   - `show_navigation`: (Public) set to false to hide navigation menu,
   - `next`: (Public) navigate's the next menu chunk, default `"98"`,
   - `previous`: (Public) navigate's the previous menu chunk or the previous menu struct default `"0"`,,
   - `split`: (Public) This is used to set the chunk size value when rendering menu_list. default value size `7`,
   - `should_close`: (Public) This triggers ExUssd to end the current registry session,
   - `display_style`: (Public) This is used to change default's display style, default ":"
   - `parent`: (Internal) saves the previous menu struct to the current menu in order to facilitate navigation,
   - `validation_menu`: (Public) Its a special Menu struct that enables the developer to validate the client input,
   - `data`: (Public) takes data as Props that will be attached to the children menu struct,
   - `default_error_message`:(Public)  This the default error message shown on invalid input. default `"Invalid Choice\n"`
  """
  @type t :: %__MODULE__{
          name: String.t(),
          callback: fun(),
          handler: fun(),
          title: String.t(),
          menu_list: [%__MODULE__{}],
          error: String.t(),
          show_navigation: boolean(),
          next: String.t(),
          previous: String.t(),
          split: integer(),
          should_close: boolean(),
          display_style: String.t(),
          parent: %__MODULE__{},
          validation_menu: %__MODULE__{},
          data: any(),
          default_error_message: String.t()
        }

  defstruct name: nil,
            callback: nil,
            handler: nil,
            title: nil,
            menu_list: [],
            error: nil,
            handle: false,
            success: false,
            show_navigation: true,
            next: "98",
            previous: "0",
            split: 7,
            should_close: false,
            display_style: ":",
            parent: nil,
            validation_menu: nil,
            data: nil,
            default_error_message: "Invalid Choice\n"

  @doc """
    Render Function is used to create a ussd Menu.

    ## Params
  The function requires two keys as parameters
    `:name` - Name of the ussd component
    `:data` - Optional data prop that will be attached to the menu struct
    `:handler` - A callback handler ExUssd.Handler

    Returns %ExUssd.Menu{} .

    ## Examples
        iex> defmodule MyHomeHandler do
        ...>   @behaviour ExUssd.Handler
        ...>   def handle_menu(menu, api_parameters, should_handle) do
        ...>     menu |> Map.put(:title, "Welcome")
        ...>   end
        ...> end

        iex> ExUssd.Menu.render(name: "Home", handler: MyHomeHandler)

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

        iex> defmodule MyHomeHandler do
        ...>   @behaviour ExUssd.Handler
        ...>   def handle_menu(menu, api_parameters, should_handle) do
        ...>    %{language: language} = Map.get(menu, data, nil)
        ...>     case language do
        ...>      "Swahili" -> menu |> Map.put(:title, "Karibu")
        ...>      _-> menu |> Map.put(:title, "Welcome")
        ...>     end
        ...>   end
        ...> end

        iex> ExUssd.Menu.render(name: "Home", data: %{language: "Swahili"}, handler: MyHomeHandler)
        %ExUssd.Menu{
        callback: #Function<2.57249658/2 in ExUssd.Menu.render/1>,
        data: nil,
        default_error_message: "Invalid Choice\n",
        display_style: ":",
        error: nil,
        handler: MyHomeHandler,
        menu_list: [],
        name: "Home",
        next: "98",
        parent: nil,
        previous: "0",
        should_close: false,
        show_navigation: true,
        show_options: true,
        split: 7,
        title: nil,
        validation_menu: nil
      }
  """

  def render(name: name, handler: handler) do
    %ExUssd.Menu{
      name: name,
      handler: handler,
      callback: fn api_parameters, should_handle ->
        menu = %ExUssd.Menu{name: name, handler: handler}
        menu.handler.handle_menu(menu, api_parameters, should_handle)
      end
    }
  end

  def render(name: name, data: data, handler: handler) do
    %ExUssd.Menu{
      name: name,
      handler: handler,
      callback: fn api_parameters, should_handle ->
        menu = %ExUssd.Menu{name: name, handler: handler, data: data}
        menu.handler.handle_menu(menu, api_parameters, should_handle)
      end
    }
  end
end
