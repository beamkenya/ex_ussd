defmodule App.Dymanic.Horizontal.NewsHandler do
  use ExUssd.Handler
  def init(menu, _api_parameters) do
    menus = fetch_api() |> Enum.map(fn %{"title" => title, "body"=> body} ->
         ExUssd.new(name: title <> "\n" <> body)
    end)

    menu
    |> ExUssd.set(title: "World News")
    |> ExUssd.dynamic(menus: menus, orientation: :horizontal)
  end

  def fetch_api do
  [
    %{
      "userId"=> 1,
      "id"=> 1,
      "title"=> "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
      "body"=> "quia et suscipit suscipit recusandae consequuntur expedita et cum reprehenderit molestiae ut ut quas totam nostrum rerum est autem sunt rem eveniet architecto"
    },
    %{
      "userId"=> 1,
      "id"=> 2,
      "title"=> "qui est esse",
      "body"=> "est rerum tempore vitae sequi sint nihil reprehenderit dolor beatae ea dolores neque fugiat blanditiis voluptate porro vel nihil molestiae ut reiciendis qui aperiam non debitis possimus qui neque nisi nulla"
    },
    %{
      "userId"=> 1,
      "id"=> 3,
      "title"=> "ea molestias quasi exercitationem repellat qui ipsa sit aut",
      "body"=> "et iusto sed quo iure voluptatem occaecati omnis eligendi aut ad voluptatem doloribus vel accusantium quis pariatur molestiae porro eius odio et labore et velit aut"
    }]
  end
end

defmodule App.Dymanic.Horizontal.MyHomeHandler do
  use ExUssd.Handler
  def init(menu, _api_parameters) do
    menu
    |> ExUssd.set(title: "Dymanic Horizontal: BBC News")
    |> ExUssd.add(ExUssd.new(name: "News", handler: App.Dymanic.Horizontal.NewsHandler))
    # |> ExUssd.add(ExUssd.new(name: "WorkLife", handler: WorkLifeHandler))
    # |> ExUssd.add(ExUssd.new(name: "Sports", handler: SportsHandler))
  end
end
