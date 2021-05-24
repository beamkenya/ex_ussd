defmodule Phoenix.ExUssd.PageLive do
  use Phoenix.ExUssd.Web, :live_view

  @impl true
  def render(assigns) do
    ~L"""
    <div>
      <div class="block ml-4">
        <button phx-click="start" class="mt-2 bg-blue-500 hover:bg-blue-700 text-white font-bold py-1 px-2 rounded">
        start session
        </button>

        <form phx-change="change_phone_number" class="mt-2">
        <%= for {phone_number, count} <- Enum.with_index(@phone_numbers) do %>
          <%= if phone_number == @phone_number do %>
            <label class="inline-flex items-center">
              <input type="radio" class="form-radio" name="radio" value="<%= phone_number %>" checked>
              <span class="ml-2">Phone <%= count + 1 %></span>
            </label>
          <% else %>
          <label class="inline-flex items-center">
              <input type="radio" class="form-radio" name="radio" value="<%= phone_number %>">
              <span class="ml-2">Phone <%= count + 1 %></span>
            </label>
          <% end %>
        <% end %>
        </form>

        <form phx-submit="user_input" class="mt-2">
          <label class="inline-flex">
            <span class="text-gray-700">DIAL: </span>
            <input name="user_input" class="form-input ml-2 block w-full" placeholder="User Input">
            <button type="submit">send</button>
          </label>
        </form>

      <div class="mt-2 text-xl font-normal emphasis-high h-1">
        <%= Phoenix.HTML.Format.text_to_html(@menu_string) %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, %{"menu" => menu, "phone_numbers" => phone_numbers}, socket) do
    phone_number = List.first(phone_numbers)

    {:ok,
     assign(socket,
       menu: menu,
       menu_string: "",
       phone_numbers: phone_numbers,
       phone_number: phone_number,
       text: ""
     )}
  end

  @impl true
  def handle_event("change_phone_number", %{"radio" => phone_number}, socket) do
    {:noreply, assign(socket, phone_number: phone_number)}
  end

  def handle_event("user_input", %{"user_input" => user_input}, socket) do
    send(self(), {:get_menu, %{text: user_input}})
    {:noreply, assign(socket, text: user_input)}
  end

  @impl true
  def handle_event("start", _, socket) do
    session_id = ExUssd.Utils.generate_id()
    send(self(), {:get_menu, %{session_id: session_id}})

    {:noreply, assign(socket, session_id: session_id)}
  end

  @impl true
  def handle_info({:get_menu, payload}, socket) do
    api_parameters = %{
      # TODO: From simulator
      "service_code" => "*544#",
      "session_id" => Map.get(payload, :session_id, socket.assigns.session_id),
      "text" => Map.get(payload, :text, socket.assigns.text),
      "phone_number" => socket.assigns.phone_number
    }

    {:ok, %{menu_string: menu_string, should_close: _should_close}} =
      ExUssd.goto(menu: socket.assigns.menu, api_parameters: api_parameters)

    socket =
      socket
      |> assign(menu_string: menu_string)

    {:noreply, socket}
  end
end
