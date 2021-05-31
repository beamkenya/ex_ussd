defmodule ExUssd do
  alias __MODULE__

  @type t :: %__MODULE__{
          name: String.t(),
          handler: fun(),
          title: {String.t(), boolean()},
          menu_list: {[%__MODULE__{}], boolean()},
          error: {String.t(), boolean()},
          show_navigation: {boolean(), boolean()},
          next: {map(), boolean()},
          previous: {map(), boolean()},
          split: {integer(), boolean()},
          should_close: {boolean(), boolean()},
          delimiter: {String.t(), boolean()},
          parent: %__MODULE__{},
          validation_menu: {%__MODULE__{}, boolean()},
          data: map(),
          id: String.t(),
          default_error: String.t(),
          continue: {boolean(), boolean()},
          show_navigation: {boolean(), boolean()}
        }

  @derive {Inspect, only: [:name, :menu_list, :title, :validation_menu]}
  defstruct name: nil,
            handler: nil,
            title: {nil, false},
            menu_list: {[], false},
            error: {nil, false},
            handle: {false, false},
            success: {false, false},
            show_navigation: {true, false},
            next: {%{name: "MORE", next: "98", delimiter: ":"}, false},
            previous: {%{name: "BACK", previous: "0", delimiter: ":"}, false},
            split: {7, false},
            should_close: {false, false},
            delimiter: {":", false},
            parent: nil,
            validation_menu: {nil, false},
            data: nil,
            id: nil,
            init: nil,
            continue: {nil, false},
            orientation: :vertical,
            default_error: "Invalid Choice\n"

  defdelegate new(opts), to: ExUssd.Op
  defdelegate add(menu, opts), to: ExUssd.Op
  defdelegate navigate(menu, opts), to: ExUssd.Op
  defdelegate set(menu, opts), to: ExUssd.Op
  defdelegate goto(opts), to: ExUssd.Op
  defdelegate end_session(opts), to: ExUssd.Op
  defdelegate dynamic(menu, opts), to: ExUssd.Op

  @doc """
    defmodule MyAppWeb.Router do
      use Phoenix.Router
      import ExUssd

      scope "/", MyAppWeb do
        pipe_through [:browser]
        simulate "/simulator",
          menu: ExUssd.new(name: "Home", handler: MyHomeHandler),
          phone_numbers: ["254700100100", "254700200200", "254700300300"]
      end
    end
  """
  defmacro simulate(path, opts \\ []) do
    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 4]
        opts = ExUssd.__options__(opts)
        # All helpers are public contracts and cannot be changed
        live("/", Phoenix.ExUssd.PageLive, :home, opts)
      end
    end
  end

  def __options__(options) do
    live_socket_path = Keyword.get(options, :live_socket_path, "/live")

    phone_numbers =
      case options[:phone_numbers] do
        nil ->
          %{phone_numbers: []}

        phone_numbers ->
          %{phone_numbers: phone_numbers}
      end

    menu =
      case options[:menu] do
        nil ->
          %{menu: nil}

        menu ->
          %{menu: menu}
      end

    session_args = [phone_numbers, menu]

    [
      session: {__MODULE__, :__session__, session_args},
      private: %{live_socket_path: live_socket_path},
      layout: {Phoenix.ExUssd.LayoutView, :root},
      as: :ex_ussd
    ]
  end

  def __session__(_conn, %{phone_numbers: phone_numbers}, %{menu: menu}) do
    %{"phone_numbers" => phone_numbers, "menu" => menu}
  end
end
