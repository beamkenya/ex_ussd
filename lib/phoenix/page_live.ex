defmodule Phoenix.ExUssd.PageLive do
  use Phoenix.ExUssd.Web, :live_view

  @impl true
  def render(assigns) do
    ~L"""
      <div>
      <%= if @show_modal do %>
        <section class="font-normal">
        <div class="fixed z-20 inset-0 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
          <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">

            <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true"></div>
            <div class="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
              <div class="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                <div class="sm:flex sm:items-start">
                  <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                    <div class="mt-2">
                      <p class="font-normal emphasis-high text-gray-500">
                      <%= Phoenix.HTML.Format.text_to_html(@menu_string) %>
                      </p>
                    </div>
                  </div>
                </div>
              </div>
              <%= if !@should_close do %>
              <form phx-change="user_input" class="px-4">
                <input class="appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none id="username" name="user_input" type="text" autocomplete="off" value="<%= @user_input %>">
              </form>
              <div class="bg-gray-50 py-3 sm:flex">
                <button phx-click="cancel" type="button" class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm">
                  Cancel
                </button>
                <button phx-click="send" type="button" class=" bg-blue-500 text-base text-white hover:bg-blue-700 mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 text-base font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm">
                  Send
                </button>
              </div>
              <% else %>
              <div class="bg-gray-50 py-3 sm:flex">
                <button phx-click="cancel" type="button" class=" bg-blue-500 text-base text-white hover:bg-blue-700 mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 text-base font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm">
                  OK
                </button>
              </div>
              <% end %>
            </div>
          </div>
        </div>
        </section>
      <% end %>
        <section class="pt-5 flex flex-col justify-center items-center" >
        <h1 class="font-normal emphasis-high text-white">choose api parameter phone number</h1>
        <form phx-change="change_phone_number" class="mt-2">
          <%= for {phone_number, count} <- Enum.with_index(@phone_numbers) do %>
            <%= if phone_number == @phone_number do %>
              <label class="inline-flex items-center">
                <input type="radio" class="form-radio" name="radio" value="<%= phone_number %>" checked>
                <span class="ml-2 font-normal emphasis-high text-white">Phone <%= count + 1 %></span>
              </label>
            <% else %>
            <label class="inline-flex items-center">
                <input type="radio" class="form-radio" name="radio" value="<%= phone_number %>">
                <span class="ml-2 font-normal emphasis-high text-white">Phone <%= count + 1 %></span>
              </label>
            <% end %>
          <% end %>
          </form>
        </div>
        </section>

        <section class="pt-16 w-full h-full flex flex-col justify-center items-center">
          <div class="w-full h-full max-h-phone max-w-xs relative">
            <div class="flex flex-col pt-16 pb-16 px-3 h-full relative z-10">
              <!--- Display --->
              <div class="flex flex-col justify-center items-center flex-grow elevation-4 rounded-t-lg">
                <div class="mt-10 text-xl font-normal text-gray-900 mb-60">
                  <%= Phoenix.HTML.Format.text_to_html(@dialer) %>
                </div>
              </div>
              <!--- Num pad --->
              <div id="num-pad" class="flex flex-col elevation-4 pb-1">
                  <div id="num-pad" class="flex flex-col elevation-4 pb-1">
                    <div class="flex num-row">
                      <%= for value <- 1..3 do %>
                        <button class="phone-button" phx-click="button_clicked" phx-value-val=<%= value %>><%= value %></button>
                      <% end %>
                    </div>
                    <div class="flex num-row">
                      <%= for value <- 4..6 do %>
                        <button class="phone-button" phx-click="button_clicked" phx-value-val=<%= value %>><%= value %></button>
                      <% end %>
                    </div>
                    <div class="flex num-row">
                      <%= for value <- 7..9 do %>
                        <button class="phone-button" phx-click="button_clicked" phx-value-val=<%= value %>><%= value %></button>
                      <% end %>
                    </div>
                    <div class="flex num-row">
                      <%= for value <- ["*", 0, "\#"] do %>
                        <button class="phone-button" phx-click="button_clicked" phx-value-val=<%= value %>><%= value %></button>
                      <% end %>
                    </div>
                  </div>
                  <div class="flex justify-center justify-items-center">
                    <button class="phone-button-secondary" phx-click="undo_last" title="Remove the last digit">
                      <div class="h-7 w-7">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2M3 12l6.414 6.414a2 2 0 001.414.586H19a2 2 0 002-2V7a2 2 0 00-2-2h-8.172a2 2 0 00-1.414.586L3 12z" />
                        </svg>
                      </div>
                    </button>
                    <button class="phone-button-call" phx-click="call" title="Execute the USSD Code">Call</button>
                    <button class="phone-button-secondary" phx-click="clear_dialer" title="Clear Dialer">
                      <div class="h-6 w-6">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                        </svg>
                      </div>
                    </button>
                  </div>
                </div>
              </div>
            <!--- Phone layout --->
            <div class="absolute z-0 top-0 bottom-0 left-0 right-0">
              <svg
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:cc="http://creativecommons.org/ns#"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:svg="http://www.w3.org/2000/svg"
                xmlns="http://www.w3.org/2000/svg"
                version="1.0"
                viewBox="0 0 508.29999 1034.2379"
                preserveAspectRatio="xMidYMid meet"
                id="svg16">
                <metadata id="metadata10"></metadata>
                <g
                  transform="matrix(0.1,0,0,-0.1,-179.85,1151.7379)"
                  stroke="none"
                  id="g14">
                  <path class="text-elevation-1" fill="currentColor" d="m 3349,11509 c -365,-4 -675,-12 -730,-18 -137,-17 -242,-46 -344,-96 -163,-79 -274,-190 -350,-350 -84,-176 -94,-265 -95,-790 -1,-327 -3,-393 -15,-409 -22,-29 -22,-643 0,-672 21,-28 21,-380 0,-408 -22,-29 -22,-641 0,-673 13,-18 15,-398 18,-3109 l 2,-3089 23,-85 c 67,-249 220,-427 452,-525 35,-15 111,-40 169,-55 58,-16 97,-29 86,-29 -15,-1 -16,-4 -7,-13 10,-10 376,-13 1760,-13 961,0 1760,4 1776,8 19,5 26,11 18,16 -7,4 29,17 81,29 341,83 541,265 629,577 l 23,80 3,3141 c 2,2767 4,3143 17,3154 22,18 22,671 0,690 -12,10 -15,145 -17,963 l -3,952 -27,95 c -33,121 -67,197 -123,275 -133,187 -346,301 -627,335 -47,6 -437,15 -865,20 -840,10 -901,10 -1854,-1 z M 6655,6320 V 2205 H 4335 2015 l -3,4109 c -2,3281 0,4111 10,4118 7,4 1053,7 2323,5 l 2310,-2 z" />
                </g>
              </svg>
            </div>
          </div>
        </section>
      </div>
    """
  end

  @impl true
  def mount(_params, %{"menu" => menu, "phone_numbers" => phone_numbers}, socket) do
    phone_number = List.first(phone_numbers)

    {:ok,
     assign(socket,
       menu: menu,
       dialer: "",
       phone_number: phone_number,
       phone_numbers: phone_numbers,
       show_modal: false,
       user_input: "",
       session_id: nil,
       menu_string: "",
       should_close: false
     )}
  end

  @impl true
  def handle_event("change_phone_number", %{"radio" => phone_number}, socket) do
    {:noreply, assign(socket, phone_number: phone_number)}
  end

  @impl true
  def handle_event("user_input", %{"user_input" => user_input}, socket) do
    {:noreply, assign(socket, user_input: user_input)}
  end

  @impl true
  def handle_event("button_clicked", %{"val" => value}, socket) do
    {:noreply, update(socket, :dialer, &(&1 <> value))}
  end

  @impl true
  def handle_event("cancel", _, socket) do
    send(self(), {:end_session, %{session_id: socket.assigns.session_id}})

    {:noreply,
     assign(socket,
       show_modal: false,
       user_input: "",
       session_id: nil,
       dialer: ""
     )}
  end

  @impl true
  def handle_event("undo_last", _params, socket) do
    {:noreply, update(socket, :dialer, fn code -> code |> String.split_at(-1) |> elem(0) end)}
  end

  @impl true
  def handle_event("clear_dialer", _params, socket) do
    {:noreply, assign(socket, :dialer, "")}
  end

  @impl true
  def handle_event("call", _params, socket) do
    session_id = ExUssd.Utils.generate_id()
    payload = process_dialer(socket.assigns.dialer)
    send(self(), {:get_menu, Map.merge(payload, %{session_id: session_id})})
    socket = assign(socket, session_id: session_id)
    {:noreply, update(socket, :show_modal, &(!&1))}
  end

  @impl true
  def handle_event("send", _, socket) do
    send(self(), {:get_menu, %{user_input: socket.assigns.user_input}})
    {:noreply, assign(socket, :user_input, "")}
  end

  @impl true
  def handle_info({:end_session, %{session_id: session_id}}, socket) do
    ExUssd.end_session(session_id: session_id)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:get_menu, payload}, socket) do
    api_parameters = %{
      "service_code" => Map.get(payload, :dialer, socket.assigns.dialer),
      "session_id" => Map.get(payload, :session_id, socket.assigns.session_id),
      "text" => Map.get(payload, :user_input, socket.assigns.user_input),
      "phone_number" => socket.assigns.phone_number
    }

    {:ok, %{menu_string: menu_string, should_close: should_close}} =
      ExUssd.goto(menu: socket.assigns.menu, api_parameters: api_parameters)

    socket =
      socket
      |> assign(menu_string: menu_string, should_close: should_close)

    {:noreply, socket}
  end

  defp process_dialer(dialer) do
    processed_dialer = dialer |> String.replace("#", "") |> String.split("*")

    if length(processed_dialer) > 2,
      do: %{dialer: get_service_code(processed_dialer), user_input: dialer},
      else: %{dialer: dialer, user_input: dialer}
  end

  def get_service_code(processed_dialer) do
    dialer = tl(processed_dialer) |> List.first()
    "*#{dialer}#"
  end
end
