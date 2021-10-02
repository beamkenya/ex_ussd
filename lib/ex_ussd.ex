defmodule ExUssd do
  alias __MODULE__

  @typedoc """
   ExUssd menu structure
  """
  @type t :: %__MODULE__{
          data: any(),
          default_error: String.t(),
          delimiter: String.t(),
          error: String.t(),
          is_zero_based: boolean(),
          menu_list: list(ExUssd.t()),
          name: String.t(),
          nav: [ExUssd.Nav.t()],
          navigate: fun(),
          orientation: atom(),
          parent: ExUssd.t(),
          resolve: fun() | mfa(),
          should_close: boolean(),
          show_navigation: boolean(),
          title: String.t()
        }

  @typedoc """
    ExUssd menu
  """
  @type menu() :: ExUssd.t()
  @typedoc """
  The Gateway payload value

  Typically you will Register a callback URL with your gateway provider that they will call whenever they get a request from a client.

  Example:
  You would have a simple endpoint that you receive POST requests from your gateway provider.

  ```elixir
  # Africa talking callback URL
  post "v1/ussd" do
    payload = conn.params

    # With the payload you can call `ExUssd.goto/1`
    
    menu = ExUssd.new(name: "HOME", resolve: AppWeb.HomeResolver)

    case ExUssd.goto(menu: menu, payload: payload) do
    {:ok, %{menu_string: menu_string, should_close: false}} ->
      "CON " <> menu_string

    {:ok, %{menu_string: menu_string, should_close: true}} ->
      # End Session
      ExUssd.end_session(session_id: session_id)

      "END " <> menu_string
    end
  end
  ```
  """
  @type payload() :: map()
  @typedoc """
  It's a map of metadata about the session
  The map contains the following keys:
  - attempt: The number of attempts the user has made to enter the menu
  - invoked_at: The time the menu was invoked
  - route: The route that was invoked
  - text: This is the text that was entered by the user. We receive this from the gateway payload.

  Example:
  ```elixir
    %{attempt: 1, invoked_at: ~U[2024-09-25 09:10:15Z], route: "*555*1#", text: "1"}
  ```
  """
  @type metadata() :: map()

  @doc """
  ExUssd provides different life cycle methods for your menu.

  `ussd_init/2` 
  This callback must be implemented in your module as it is called when the menu is first invoked.
  This callback is invoked once

  `ussd_init/2` is called with the following arguments:

  - menu: The menu that was invoked
  - payload: The payload that was received from the gateway provider

  Example:
      iex> defmodule AppWeb.HomeResolver do
      ...>  use ExUssd
      ...>  def ussd_init(menu, _) do
      ...>    ExUssd.set(menu, title: "Enter your PIN")
      ...>  end
      ...> end
      iex> # To simulate a user entering a PIN, you can use the `ExUssd.to_string/2` method.
      iex> menu = ExUssd.new(name: "HOME", resolve: AppWeb.HomeResolver)
      iex> ExUssd.to_string!(menu, :ussd_init, [])
      "Enter your PIN"
  """

  @callback ussd_init(
              menu :: menu(),
              payload :: payload()
            ) :: menu()

  @doc """
  `ussd_callback/3` is a the second life cycle method.
  This callback is invoked every time the user enters a value into the current menu.
  You can think of `ussd_callback/3` as a optional validation callback.

  `ussd_callback/3` is called with the following arguments:

  - menu: The menu that was invoked
  - payload: The payload that was received from the gateway provider
  - metadata: The metadata about the session

   Example:
      iex> defmodule AppWeb.PinResolver do
      ...>  use ExUssd
      ...>  def ussd_init(menu, _) do
      ...>    ExUssd.set(menu, title: "Enter your PIN")
      ...>  end
      ...>  def ussd_callback(menu, payload, _) do
      ...>    if payload.text == "5555" do
      ...>       ExUssd.set(menu, resolve: &success_menu/2)
      ...>    else
      ...>      ExUssd.set(menu, error: "Wrong PIN\\n")
      ...>    end
      ...>  end
      ...>  def success_menu(menu, _) do
      ...>    menu
      ...>    |> ExUssd.set(title: "You have Entered the Secret Number, 5555")
      ...>    |> ExUssd.set(should_close: true)
      ...>  end
      ...> end
      iex> # To simulate a user entering correct PIN, you can use the `ExUssd.to_string/3` method.
      iex> menu = ExUssd.new(name: "HOME", resolve: AppWeb.PinResolver)
      iex> ExUssd.to_string!(menu, :ussd_callback, [payload: %{text: "5555"}])
      "You have Entered the Secret Number, 5555"
      iex> # To simulate a user entering wrong PIN, you can use the `ExUssd.to_string/3` method.
      iex> menu = ExUssd.new(name: "HOME", resolve: AppWeb.PinResolver)
      iex> ExUssd.to_string!(menu, :ussd_callback, payload: %{text: "5556"})
      "Wrong PIN\\nEnter your PIN"

  ## Note: 
  #### Use `default_error`

  `ussd_callback/3` will use the default error message if the callback returns `false`.

    Example:
        iex> defmodule AppWeb.PinResolver do
        ...>  use ExUssd
        ...>  def ussd_init(menu, _) do
        ...>    ExUssd.set(menu, title: "Enter your PIN")
        ...>  end
        ...>  def ussd_callback(menu, payload, _) do
        ...>    if payload.text == "5555" do
        ...>       ExUssd.set(menu, resolve: &success_menu/2)
        ...>    end
        ...>  end
        ...>  def success_menu(menu, _) do
        ...>    menu
        ...>    |> ExUssd.set(title: "You have Entered the Secret Number, 5555")
        ...>    |> ExUssd.set(should_close: true)
        ...>  end
        ...> end
        iex> # To simulate a user entering wrong PIN.
        iex> menu = ExUssd.new(name: "PIN", resolve: AppWeb.PinResolver)
        iex> ExUssd.to_string!(menu, :ussd_callback, payload: %{text: "5556"})
        "Invalid Choice\\nEnter your PIN"

  #### Life cycle

  `ussd_callback/3` is called before ussd menu list is resolved.
  If the callback returns `false` or it's not implemented, ExUssd will proccess to resolve the user input section from the menu list.

  Example:
          iex> defmodule AppWeb.ProductResolver do
          ...>  use ExUssd
          ...>  def ussd_init(menu, _) do
          ...>    menu 
          ...>    |> ExUssd.set(title: "Product List, Enter 5555 for Offers")
          ...>    |> ExUssd.add(ExUssd.new(name: "Product A", resolve: &product_a/2))
          ...>    |> ExUssd.add(ExUssd.new(name: "Product B", resolve: &product_b/2))
          ...>    |> ExUssd.add(ExUssd.new(name: "Product C", resolve: &product_c/2))
          ...> end
          ...>  def ussd_callback(menu, payload, _) do
          ...>    if payload.text == "5555" do
          ...>       ExUssd.set(menu, resolve: &product_offer/2)
          ...>    end
          ...>  end
          ...>  def product_a(menu, _payload), do: menu |> ExUssd.set(title: "selected product a")
          ...>  def product_b(menu, _payload), do: menu |> ExUssd.set(title: "selected product b")
          ...>  def product_c(menu, _payload), do: menu |> ExUssd.set(title: "selected product c")
          ...>  def product_offer(menu, _payload), do: menu |> ExUssd.set(title: "selected product offer")
          ...> end
          iex> menu = ExUssd.new(name: "HOME", resolve: AppWeb.ProductResolver)
          iex> # To simulate a user entering "5555"
          iex> ExUssd.to_string!(menu, simulate: true, payload: %{text: "5555"})
          "selected product offer"
          iex> # To simulate a user selecting option "1"
          iex> ExUssd.to_string!(menu, simulate: true, payload: %{text: "1"})
          "selected product a"
  """
  @callback ussd_callback(
              menu :: menu(),
              payload :: payload(),
              metadata :: metadata()
            ) :: menu()

  @doc """
  `ussd_after_callback/3` is a the third life cycle method.
  This callback is invoked every time before ussd menu is rendered. It's invoke after menu_list is resolved.
  You can think of `ussd_after_callback/3` as a optional clean up callback.

  Example:
          iex> defmodule AppWeb.ProductResolver do
          ...>  use ExUssd
          ...>  def ussd_init(menu, _) do
          ...>    menu 
          ...>    |> ExUssd.set(title: "Product List")
          ...>    |> ExUssd.add(ExUssd.new(name: "Product A", resolve: &product_a/2))
          ...>    |> ExUssd.add(ExUssd.new(name: "Product B", resolve: &product_b/2))
          ...>    |> ExUssd.add(ExUssd.new(name: "Product C", resolve: &product_c/2))
          ...> end
          ...>  def ussd_after_callback(%{error: true} = _menu, _payload, _metadata) do
          ...>      # Use the gateway payload and metadata to capture user metrics on error
          ...>  end
          ...>  def ussd_after_callback(_menu, _payload, _metadata) do
          ...>      # Use the gateway payload and metadata to capture user metrics before navigating to next menu
          ...>  end
          ...>  def product_a(menu, _payload), do: menu |> ExUssd.set(title: "selected product a")
          ...>  def product_b(menu, _payload), do: menu |> ExUssd.set(title: "selected product b")
          ...>  def product_c(menu, _payload), do: menu |> ExUssd.set(title: "selected product c")
          ...> end
          iex> menu = ExUssd.new(name: "HOME", resolve: AppWeb.ProductResolver)
          iex> # To simulate a user selecting option "1"
          iex> ExUssd.to_string!(menu, simulate: true, payload: %{text: "1"})
          "selected product a"
          iex> # To simulate a user selecting invalid option "42"
          iex> ExUssd.to_string!(menu, simulate: true, payload: %{text: "42"})
          "Invalid Choice\\nProduct List\\n1:Product A\\n2:Product B\\n3:Product C"

   # Note:
    `ussd_after_callback/3` can to used to render menu if set conditions are met.
    For example, you can use `ussd_after_callback/3` to render a custom menu if the user has not entered the correct PIN.

    Example:
          iex> defmodule AppWeb.HomeResolver do
          ...>  use ExUssd
          ...>  def ussd_init(menu, _) do
          ...>      ExUssd.set(menu, title: "Enter your PIN")
          ...>  end
          ...>  def ussd_callback(menu, payload, _) do
          ...>    if payload.text == "5555" do
          ...>      ExUssd.set(menu, resolve: &success_menu/2)
          ...>    else
          ...>      ExUssd.set(menu, error: "Wrong PIN\\n")
          ...>    end
          ...>  end
          ...>  def ussd_after_callback(%{error: true} = menu, _payload, %{attempt: 3}) do
          ...>   menu
          ...>   |> ExUssd.set(title: "Account is locked, you have entered the wrong PIN 3 times")
          ...>   |> ExUssd.set(should_close: true)
          ...>  end
          ...>  def success_menu(menu, _) do
          ...>    menu
          ...>    |> ExUssd.set(title: "You have Entered the Secret Number, 5555")
          ...>    |> ExUssd.set(should_close: true)
          ...>  end
          ...> end
          iex> # To simulate a user entering wrong PIN 3 times.
          iex> menu = ExUssd.new(name: "PIN", resolve: AppWeb.HomeResolver)
          iex> ExUssd.to_string!(menu, :ussd_after_callback, payload: %{text: "5556", attempt: 3})
          "Account is locked, you have entered the wrong PIN 3 times"
  """
  @callback ussd_after_callback(
              menu :: menu(),
              payload :: payload(),
              metadata :: metadata()
            ) :: any()

  @optional_callbacks ussd_callback: 3,
                      ussd_after_callback: 3

  defstruct [
    :data,
    :error,
    :is_zero_based,
    :name,
    :navigate,
    :parent,
    :resolve,
    :title,
    delimiter: Application.get_env(:ex_ussd, :delimiter) || ":",
    default_error: Application.get_env(:ex_ussd, :default_error) || "Invalid Choice\n",
    menu_list: [],
    nav:
      Application.get_env(:ex_ussd, :nav) ||
        [
          ExUssd.Nav.new(
            type: :home,
            name: "HOME",
            match: "00",
            reverse: true,
            orientation: :vertical
          ),
          ExUssd.Nav.new(type: :back, name: "BACK", match: "0", right: 1),
          ExUssd.Nav.new(type: :next, name: "MORE", match: "98")
        ],
    orientation: :vertical,
    split: Application.get_env(:ex_ussd, :split) || 7,
    should_close: false,
    show_navigation: true
  ]

  defmacro __using__([]) do
    quote do
      @behaviour ExUssd
    end
  end

  @doc """
  Add menu to ExUssd menu list.

  Arguments:
    - menu :: menu() :: The parent menu
    - menu :: menu() :: The menu to add to the parent menu list.

  ## Example
      iex> resolve = fn menu, _payload -> 
      ...>  menu 
      ...>  |> ExUssd.set(title: "Menu title")
      ...>  |> ExUssd.add(ExUssd.new(name: "option 1", resolve: &(ExUssd.set(&1, title: "option 1"))))
      ...>  |> ExUssd.add(ExUssd.new(name: "option 2", resolve: &(ExUssd.set(&1, title: "option 2"))))
      ...> end
      iex> menu = ExUssd.new(name: "HOME", resolve: resolve)
      iex> ExUssd.to_string!(menu, [])
      "Menu title\\n1:option 1\\n2:option 2"
  """
  defdelegate add(menu, child), to: ExUssd.Op

  @doc """
  Add menus to ExUssd menu list.

  Arguments:
    - `menu` :: menu() :: The parent menu
    - `menus` :: list(menu()) :: The menu to add to the parent menu list.
    - `opts` :: keyword_args() :: Options to pass to `ExUssd.add/3`

    Example:
          iex> defmodule AppWeb.LocationResolver do
          ...>  use ExUssd
          ...>  def ussd_init(menu, _) do
          ...>   # Get locations from database
          ...>    locations = Enum.map(1..5, &Integer.to_string/1)
          ...>    # convert locations to menus
          ...>    menus = Enum.map(locations, fn location ->
          ...>       ExUssd.new(name: "Location " <> location, data: %{name: location})
          ...>    end)
          ...>    menu
          ...>    |> ExUssd.set(title: "Select Location")
          ...>    |> ExUssd.add(menus, resolve: &(ExUssd.set(&1, title: "Location " <> &1.data.name)))
          ...>  end
          ...> end
          iex> menu = ExUssd.new(name: "HOME", resolve: AppWeb.LocationResolver)
          iex> ExUssd.to_string!(menu, [])
          "Select Location\\n1:Location 1\\n2:Location 2\\n3:Location 3\\n4:Location 4\\n5:Location 5"
  """
  defdelegate add(menu, menus, opts), to: ExUssd.Op

  @doc """
  Teminates session.
    ```elixir
        ExUssd.end_session(session_id: "sn1")
    ```
  """
  defdelegate end_session(opts), to: ExUssd.Op

  @doc """
  `ExUssd.goto/1` is called when the gateway provider calls the callback URL.

    Keyword Arguments:

    - `payload`: The payload from the gateway provider.
    - `menu`: The menu to be rendered.

    Example:

    ```elixir
      case ExUssd.goto(menu: menu, payload: payload) do
      {:ok, %{menu_string: menu_string, should_close: false}} ->
        "CON " <> menu_string

      {:ok, %{menu_string: menu_string, should_close: true}} ->
        # End Session
        ExUssd.end_session(session_id: session_id)

        "END " <> menu_string
      end
    ```
  """
  defdelegate goto(opts), to: ExUssd.Op

  @doc """
  `ExUssd.new/1` - Creates a new ExUssd menu.

  Keyword Arguments:
     - `name` :: The name of the menu.
     - `resolve` :: The resolve function to be called when the menu is selected.
     - `orientation` :: The orientation of the menu.
     - `is_zero_based` :: indicates whether the menu list is zero based.

  Example:
      iex> resolve = fn menu, _payload -> 
      ...>  menu 
      ...>  |> ExUssd.set(title: "Menu title")
      ...>  |> ExUssd.add(ExUssd.new(name: "option 1", resolve: &(ExUssd.set(&1, title: "option 1"))))
      ...>  |> ExUssd.add(ExUssd.new(name: "option 2", resolve: &(ExUssd.set(&1, title: "option 2"))))
      ...> end
      iex> menu = ExUssd.new(name: "HOME", resolve: resolve)
      iex> ExUssd.to_string!(menu, [])
      "Menu title\\n1:option 1\\n2:option 2"
      iex> # Change menu orientation
      iex> menu = ExUssd.new(name: "HOME", resolve: resolve, orientation: :horizontal)
      iex> ExUssd.to_string!(menu, [])
      "1:2\\noption 1\\n00:HOME\\nBACK:0 MORE:98"

  ## zero based
  Used when the menu list is zero based.

  Example:
      iex> resolve = fn menu, _payload -> 
      ...>  menu 
      ...>  |> ExUssd.set(title: "Menu title")
      ...>  |> ExUssd.add(ExUssd.new(name: "offers", resolve: &(ExUssd.set(&1, title: "offers"))))
      ...>  |> ExUssd.add(ExUssd.new(name: "option 1", resolve: &(ExUssd.set(&1, title: "option 1"))))
      ...>  |> ExUssd.add(ExUssd.new(name: "option 2", resolve: &(ExUssd.set(&1, title: "option 2"))))
      ...> end
      iex> menu = ExUssd.new(name: "HOME", is_zero_based: true, resolve: resolve)
      iex> ExUssd.to_string!(menu, [])
      "Menu title\\n0:offers\\n1:option 1\\n2:option 2"

  NOTE:
    `ExUssd.new/1` can be used to create a menu with a callback function.

    Use the anonymous function syntax to create menu if you want to perform some action before the menu is rendered.

    Remember to use `ExUssd.set` to set the menu name and the resolve function/module.

    Example:

      iex> defmodule User do
      ...>  def get_user(phone_number), do: %{name: "John", phone_number: phone_number, type: :personal}
      ...> end
      iex> defmodule HomeResolver do
      ...>  def home(%ExUssd{data: %{name: name}} = menu, _) do
      ...>    menu 
      ...>    |> ExUssd.set(title: "Welcome " <> name)
      ...>    |> ExUssd.add(ExUssd.new(name: "Product A", resolve: &product_a/2))
      ...>    |> ExUssd.add(ExUssd.new(name: "Product B", resolve: &product_b/2))
      ...>    |> ExUssd.add(ExUssd.new(name: "Product C", resolve: &product_c/2))
      ...>  end
      ...>  def product_a(menu, _payload), do: menu |> ExUssd.set(title: "selected product a")
      ...>  def product_b(menu, _payload), do: menu |> ExUssd.set(title: "selected product b")
      ...>  def product_c(menu, _payload), do: menu |> ExUssd.set(title: "selected product c")
      ...> end
      iex> menu = ExUssd.new(fn menu, %{phone: phone} = _payload ->
      ...>    user = User.get_user(phone)
      ...>    menu
      ...>    |> ExUssd.set(name: "Home")
      ...>    |> ExUssd.set(data: user)
      ...>    |> ExUssd.set(resolve: &HomeResolver.home/2)
      ...> end)
      iex> ExUssd.to_string!(menu, [payload: %{text: "*544#", phone: "072000000"}])
      "Welcome John\\n1:Product A\\n2:Product B\\n3:Product C"

   You can also use the anonymous function syntax to create menu if you want to create dymamic menu name.

    Example:
      iex> defmodule User do
      ...>  def get_user(phone_number), do: %{name: "John", phone_number: phone_number, type: :personal}
      ...> end
      iex> defmodule HomeResolver do
      ...>  def home(menu, %{phone: phone} = _payload) do
      ...>    user = User.get_user(phone)
      ...>    menu 
      ...>    |> ExUssd.set(title: "Welcome "<> user.name)
      ...>    |> ExUssd.set(data: user)
      ...>    |> ExUssd.add(ExUssd.new(name: "Product A", resolve: &product_a/2))
      ...>    |> ExUssd.add(ExUssd.new(name: "Product B", resolve: &product_b/2))
      ...>    |> ExUssd.add(ExUssd.new(name: "Product C", resolve: &product_c/2))
      ...>    |> ExUssd.add(ExUssd.new(&account/2))
      ...>  end
      ...>  def product_a(menu, _payload), do: menu |> ExUssd.set(title: "selected product a")
      ...>  def product_b(menu, _payload), do: menu |> ExUssd.set(title: "selected product b")
      ...>  def product_c(menu, _payload), do: menu |> ExUssd.set(title: "selected product c")
      ...>  def account(%{data: %{type: :personal, name: name}} = menu, _payload) do
      ...>    # Get Personal account details, then set as data
      ...>    menu 
      ...>    |> ExUssd.set(name: "Personal account")
      ...>    |> ExUssd.set(resolve: &(ExUssd.set(&1, title: "Personal account")))
      ...>  end
      ...>  def account(%{data: %{type: :business, name: name}} = menu, _payload) do
      ...>    # Get Business account details, then set as data
      ...>    menu 
      ...>    |> ExUssd.set(name: "Business account")
      ...>    |> ExUssd.set(resolve: &(ExUssd.set(&1, title: "Business account")))
      ...>  end
      ...> end
      iex> menu = ExUssd.new(name: "HOME", resolve: &HomeResolver.home/2)
      iex> ExUssd.to_string!(menu, [payload: %{text: "*544#", phone: "072000000"}])
      "Welcome John\\n1:Product A\\n2:Product B\\n3:Product C\\n4:Personal account"
  """
  defdelegate new(opts), to: ExUssd.Op

  @doc """
  `ExUssd.new/2` - Creates a new ExUssd menu.

  Arguments:
    name: The name of the menu.
    resolve: The resolve function/module.

  It similiar to `ExUssd.new/1` that takes callback function.
  The only difference is that it takes a static name argument.

   Example:
      iex> defmodule User do
      ...>  def get_user(phone_number), do: %{name: "John", phone_number: phone_number, type: :personal}
      ...> end
      iex> defmodule HomeResolver do
      ...>  def home(menu, %{phone: phone} = _payload) do
      ...>    user = User.get_user(phone)
      ...>    menu 
      ...>    |> ExUssd.set(title: "Welcome "<> user.name)
      ...>    |> ExUssd.set(data: user)
      ...>    |> ExUssd.add(ExUssd.new(name: "Product A", resolve: &product_a/2))
      ...>    |> ExUssd.add(ExUssd.new(name: "Product B", resolve: &product_b/2))
      ...>    |> ExUssd.add(ExUssd.new(name: "Product C", resolve: &product_c/2))
      ...>    |> ExUssd.add(ExUssd.new("Account", &account/2))
      ...>  end
      ...>  def product_a(menu, _payload), do: menu |> ExUssd.set(title: "selected product a")
      ...>  def product_b(menu, _payload), do: menu |> ExUssd.set(title: "selected product b")
      ...>  def product_c(menu, _payload), do: menu |> ExUssd.set(title: "selected product c")
      ...>  def account(%{data: %{type: :personal, name: name}} = menu, _payload) do
      ...>    # Get Personal account details, then set as data
      ...>     ExUssd.set(menu, resolve: &(ExUssd.set(&1, title: "Personal account")))
      ...>  end
      ...>  def account(%{data: %{type: :business, name: name}} = menu, _payload) do
      ...>    # Get Business account details, then set as data
      ...>    ExUssd.set(menu, resolve: &(ExUssd.set(&1, title: "Business account")))
      ...>  end
      ...> end
      iex> menu = ExUssd.new(name: "HOME", resolve: &HomeResolver.home/2)
      iex> ExUssd.to_string!(menu, [payload: %{text: "*544#", phone: "072000000"}])
      "Welcome John\\n1:Product A\\n2:Product B\\n3:Product C\\n4:Account"
  """
  defdelegate new(name, function), to: ExUssd.Op

  @doc """
  `ExUssd.set/2` - Sets the menu field.

  Arguments:
    menu: The menu to set.
    field: The field to set.

  It sets the field of the menu.
  ## Settable Fields
    - **`:data`** Set data to pass through to next menu. N/B - ExUssd menu are stateful unless using `ExUssd.new/2` with `:name` and `:resolve` as arguments;

      ```elixir
        data = %{name: "John Doe"}
        # stateful
        menu
        |> ExUssd.set(data: data)
        |> ExUssd.add(ExUssd.new(&check_balance/2))
        
        menu
        |> ExUssd.set(data: data)
        |> ExUssd.add(ExUssd.new("Check Balance", &check_balance/2))
      
        # stateless
        menu
        |> ExUssd.add(ExUssd.new(data: data, name: "Check Balance", resolve: &check_balance/2))
        ```

    - **`:delimiter`** Set's menu style delimiter. Default- `:`
    - **`:default_error`** Default error shown on invalid input
    - **`:error`** Set custom error message

    - **`:name`** Sets the name of the menu
    - **`:nav`** Its used to set a new ExUssd Nav menu, see `ExUssd.Nav.new/1`

    - **`:orientation`** Sets the menu orientation. Available option;
      - `:horizontal` - Left to right. Blog/articles style menu
      - `vertical` - Top to bottom(default)
    - **`:resolve`** set the resolve function/module
    - **`:should_close`** Indicate whether to USSD session should end or continue
    - **`:show_navigation`** Set show navigation menu. Default - `true`
    - **`:split`** Set menu batch size. Default - 7
    - **`:title`** Set menu title
  """
  defdelegate set(menu, opts), to: ExUssd.Op

  @doc """
  Use `ExUssd.to_string/2` to get menu string representation and should close value which indicates if the session.
  `ExUssd.to_string/2` takes a menu and opts.

  Example:
          iex> defmodule AppWeb.ProductResolver do
          ...>  use ExUssd
          ...>  def ussd_init(menu, _) do
          ...>    menu 
          ...>    |> ExUssd.set(title: "Product List")
          ...>    |> ExUssd.add(ExUssd.new(name: "Product A", resolve: &product_a/2))
          ...>    |> ExUssd.add(ExUssd.new(name: "Product B", resolve: &product_b/2))
          ...>    |> ExUssd.add(ExUssd.new(name: "Product C", resolve: &product_c/2))
          ...> end
          ...>  def product_a(menu, _payload), do: menu |> ExUssd.set(title: "selected product a")
          ...>  def product_b(menu, _payload), do: menu |> ExUssd.set(title: "selected product b")
          ...>  def product_c(menu, _payload), do: menu |> ExUssd.set(title: "selected product c")
          ...> end
          iex> menu = ExUssd.new(name: "HOME", resolve: AppWeb.ProductResolver)
          iex> # Simulate the first time user enters the menu
          iex> ExUssd.to_string(menu, [])
          {:ok, %{menu_string: "Product List\\n1:Product A\\n2:Product B\\n3:Product C", should_close: false}}
          iex> # To simulate a user selecting option "1"
          iex> ExUssd.to_string(menu, [simulate: true, payload: %{text: "1"}])
          {:ok, %{menu_string: "selected product a", should_close: false}}
          
  NOTE:
  If your `ussd_init/2` callback expects `data` field to have values, Use `init_data`.

  Example:
          iex> defmodule AppWeb.ProductResolver do
          ...>  use ExUssd
          ...>  def ussd_init(%ExUssd{data: %{user_name: user_name}} = menu, _) do
          ...>    menu 
          ...>    |> ExUssd.set(title: "Welcome " <> user_name <> ", Select Product")
          ...>    |> ExUssd.add(ExUssd.new(name: "Product A", resolve: &product_a/2))
          ...>    |> ExUssd.add(ExUssd.new(name: "Product B", resolve: &product_b/2))
          ...>    |> ExUssd.add(ExUssd.new(name: "Product C", resolve: &product_c/2))
          ...> end
          ...>  def product_a(menu, _payload), do: menu |> ExUssd.set(title: "selected product a")
          ...>  def product_b(menu, _payload), do: menu |> ExUssd.set(title: "selected product b")
          ...>  def product_c(menu, _payload), do: menu |> ExUssd.set(title: "selected product c")
          ...> end
          iex> menu = ExUssd.new(name: "HOME", resolve: AppWeb.ProductResolver)
          iex> # Simulate the first time user enters the menu
          iex> ExUssd.to_string(menu, init_data: %{user_name: "John"})
          {:ok, %{menu_string: "Welcome John, Select Product\\n1:Product A\\n2:Product B\\n3:Product C", should_close: false}}
  """
  defdelegate to_string(menu, opts), to: ExUssd.Op

  @doc """
  `ExUssd.to_string/3` is similar to `ExUssd.to_string/2`
  The only difference is that it takes a `menu`, `atom` and `opts`.
  Its used to test the menu life cycle.

  Example:
        iex> defmodule AppWeb.PinResolver do
        ...>  use ExUssd
        ...>  def ussd_init(menu, _) do
        ...>    ExUssd.set(menu, title: "Enter your PIN")
        ...>  end
        ...>  def ussd_callback(menu, payload, _) do
        ...>    if payload.text == "5555" do
        ...>       ExUssd.set(menu, resolve: &success_menu/2)
        ...>    end
        ...>  end
        ...>  def success_menu(menu, _) do
        ...>    menu
        ...>    |> ExUssd.set(title: "You have Entered the Secret Number, 5555")
        ...>    |> ExUssd.set(should_close: true)
        ...>  end
        ...> end
        iex> menu = ExUssd.new(name: "PIN", resolve: AppWeb.PinResolver)
        iex> # Get `ussd_init/2` menu string representation
        iex> ExUssd.to_string(menu, :ussd_init, [])
        {:ok, %{menu_string: "Enter your PIN", should_close: false}}
        iex> # Get `ussd_callback/2` menu string representation
        iex> ExUssd.to_string(menu, :ussd_callback, payload: %{text: "5555"})
        {:ok, %{menu_string: "You have Entered the Secret Number, 5555", should_close: true}}
  """
  defdelegate to_string(menu, atom, opts), to: ExUssd.Op

  @doc """
  `ExUssd.to_string!/2` gets the menu string text from `ExUssd.to_string/2`
  See `ExUssd.to_string/2` for more details.

  Example:
          iex> defmodule AppWeb.ProductResolver do
          ...>  def products(menu, _) do
          ...>    menu 
          ...>    |> ExUssd.set(title: "Product List")
          ...>    |> ExUssd.add(ExUssd.new(name: "Product A", resolve: &product_a/2))
          ...>    |> ExUssd.add(ExUssd.new(name: "Product B", resolve: &product_b/2))
          ...>    |> ExUssd.add(ExUssd.new(name: "Product C", resolve: &product_c/2))
          ...> end
          ...>  def product_a(menu, _payload), do: menu |> ExUssd.set(title: "selected product a")
          ...>  def product_b(menu, _payload), do: menu |> ExUssd.set(title: "selected product b")
          ...>  def product_c(menu, _payload), do: menu |> ExUssd.set(title: "selected product c")
          ...> end
          iex> menu = ExUssd.new(name: "HOME", resolve: &AppWeb.ProductResolver.products/2)
          iex> # Simulate the first time user enters the menu
          iex> ExUssd.to_string!(menu, [])
          "Product List\\n1:Product A\\n2:Product B\\n3:Product C"
  """
  defdelegate to_string!(menu, opts), to: ExUssd.Op

  @doc """
  `ExUssd.to_string!/3` gets the menu string text from `ExUssd.to_string/3`
  See `ExUssd.to_string/3` for more details.
   Example:
        iex> defmodule AppWeb.PinResolver do
        ...>  use ExUssd
        ...>  def ussd_init(menu, _) do
        ...>    ExUssd.set(menu, title: "Enter your PIN")
        ...>  end
        ...>  def ussd_callback(menu, payload, _) do
        ...>    if payload.text == "5555" do
        ...>       ExUssd.set(menu, resolve: &success_menu/2)
        ...>    end
        ...>  end
        ...>  def success_menu(menu, _) do
        ...>    menu
        ...>    |> ExUssd.set(title: "You have Entered the Secret Number, 5555")
        ...>    |> ExUssd.set(should_close: true)
        ...>  end
        ...> end
        iex> menu = ExUssd.new(name: "PIN", resolve: AppWeb.PinResolver)
        iex> # Get `ussd_init/2` menu string representation
        iex> ExUssd.to_string!(menu, :ussd_init, [])
        "Enter your PIN"
        iex> # Get `ussd_callback/2` menu string representation
        iex> ExUssd.to_string!(menu, :ussd_callback, payload: %{text: "5555"})
        "You have Entered the Secret Number, 5555"
  """
  defdelegate to_string!(menu, atom, opts), to: ExUssd.Op
end
