defmodule ExUssd do
  @moduledoc false
  alias __MODULE__

  @type t :: %__MODULE__{
          name: String.t(),
          resolve: fun() | mfa(),
          navigate: fun(),
          title: String.t(),
          parent: ExUssd.t(),
          data: any(),
          error: String.t(),
          show_navigation: boolean(),
          should_close: boolean(),
          delimiter: String.t(),
          default_error: String.t(),
          orientation: term(),
          menu_list: list(ExUssd.t())
        }

  defstruct [
    :name,
    :resolve,
    :navigate,
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
      ExUssd.Nav.new(
        type: :home,
        name: "HOME",
        match: "00",
        reverse: true,
        orientation: :vertical
      ),
      ExUssd.Nav.new(type: :back, name: "BACK", match: "0", right: 1),
      ExUssd.Nav.new(type: :next, name: "MORE", match: "98")
    ]
  ]

  @type menu() :: ExUssd.t()
  @type payload() :: map()
  @type metadata() :: map()

  @callback ussd_init(
              menu :: menu(),
              payload :: payload()
            ) :: menu()

  @callback ussd_callback(
              menu :: menu(),
              payload :: payload(),
              metadata :: metadata()
            ) :: menu()

  @callback ussd_after_callback(
              menu :: menu(),
              payload :: payload(),
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
  defdelegate end_session(opts), to: ExUssd.Op
  defdelegate goto(opts), to: ExUssd.Op
  defdelegate to_string(menu, opts), to: ExUssd.Op
  defdelegate to_string(menu, atom, opts), to: ExUssd.Op
end
