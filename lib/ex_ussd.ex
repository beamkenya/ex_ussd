defmodule ExUssd do
  alias __MODULE__

  @type t :: %__MODULE__{
          name: String.t(),
          resolve: any(),
          title: String.t(),
          parent: ExUssd.t(),
          data: any(),
          error: String.t(),
          show_navigation: boolean(),
          should_close: boolean(),
          delimiter: String.t(),
          default_error: String.t(),
          orientation: atom(),
          menu_list: list(ExUssd.t())
        }

  defstruct [
    :name,
    :resolve,
    :title,
    :parent,
    :data,
    :error,
    split: 7,
    show_navigation: true,
    should_close: false,
    delimiter: ":",
    default_error: "Invalid Choice\n",
    orientation: :vertical,
    menu_list: [],
    nav: [
      ExUssd.Nav.new(type: :home, name: "HOME", match: "00", orientation: :vertical),
      ExUssd.Nav.new(type: :back, name: "BACK", match: "0"),
      ExUssd.Nav.new(type: :next, name: "MORE", match: "98")
    ]
  ]

  @type menu() :: ExUssd.t()
  @type api_parameters() :: map()
  @type metadata() :: map()

  @callback ussd_init(
              menu :: menu(),
              api_parameters :: api_parameters(),
              metadata :: map()
            ) :: menu()

  @callback ussd_callback(
              menu :: menu(),
              api_parameters :: api_parameters(),
              metadata :: metadata()
            ) :: menu()

  @callback ussd_after_callback(
              menu :: menu(),
              api_parameters :: api_parameters(),
              metadata :: metadata()
            ) :: any()

  @optional_callbacks ussd_callback: 3,
                      ussd_after_callback: 3

  defmacro __using__([]) do
    quote do
      @behaviour ExUssd
    end
  end

  defdelegate new(opts), to: ExUssd.Op
  defdelegate set(menu, opts), to: ExUssd.Op
  defdelegate add(menu, child), to: ExUssd.Op
  defdelegate add(menu, menus, opts), to: ExUssd.Op
end
