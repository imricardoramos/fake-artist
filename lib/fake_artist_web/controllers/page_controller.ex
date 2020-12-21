defmodule FakeArtistWeb.PageController do
  use FakeArtistWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", room_uuid: UUID.uuid4())
  end
  def room(conn, _params) do
    render(conn, "room.html")
  end
end
