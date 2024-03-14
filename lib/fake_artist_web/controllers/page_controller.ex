defmodule FakeArtistWeb.PageController do
  use FakeArtistWeb, :controller

  def index(conn, _params) do
    render(conn, :index, room_uuid: UUID.uuid4())
  end
  def room(conn, _params) do
    render(conn, :room)
  end
end
