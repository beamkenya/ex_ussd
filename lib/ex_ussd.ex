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
      iex> ExUssd.to_string!(menu, :ussd_callback, [payload: %{text: "5555"}, init_text: "1"])
      "You have Entered the Secret Number, 5555"
      iex> # To simulate a user entering wrong PIN, you can use the `ExUssd.to_string/3` method.
      iex> menu = ExUssd.new(name: "HOME", resolve: AppWeb.PinResolver)
      iex> ExUssd.to_string!(menu, :ussd_callback, payload: %{text: "5556"}, init_text: "1")
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
        iex> ExUssd.to_string!(menu, :ussd_callback, payload: %{text: "5556"}, init_text: "1")
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
          iex> ExUssd.to_string!(menu, simulate: true, payload: %{text: "5555"}, init_text: "1")
          "selected product offer"
          iex> # To simulate a user selecting option "1"
          iex> ExUssd.to_string!(menu, simulate: true, payload: %{text: "1"}, init_text: "1")
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
          iex> ExUssd.to_string!(menu, simulate: true, payload: %{text: "1"}, init_text: "1")
          "selected product a"
          iex> # To simulate a user selecting invalid option "42"
          iex> ExUssd.to_string!(menu, simulate: true, payload: %{text: "42"}, init_text: "1")
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
          iex> ExUssd.to_string!(menu, :ussd_after_callback, payload: %{text: "5556", attempt: 3}, init_text: "1")
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

  defdelegate add(menu, child), to: ExUssd.Op
  defdelegate add(menu, menus, opts), to: ExUssd.Op
  defdelegate end_session(opts), to: ExUssd.Op
  defdelegate goto(opts), to: ExUssd.Op
  defdelegate new(opts), to: ExUssd.Op
  defdelegate new(name, function), to: ExUssd.Op
  defdelegate set(menu, opts), to: ExUssd.Op
  defdelegate to_string(menu, opts), to: ExUssd.Op
  defdelegate to_string(menu, atom, opts), to: ExUssd.Op
  defdelegate to_string!(menu, opts), to: ExUssd.Op
  defdelegate to_string!(menu, atom, opts), to: ExUssd.Op
end
