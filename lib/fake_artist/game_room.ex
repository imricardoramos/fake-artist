defmodule FakeArtist.GameRoom do
  use FakeArtistWeb, :channel
  # Smash Bros Wii Player Colors
  @colors ["#F52E2E", "#5463FF", "#FFC717", "#1F9E40", "#FF6619"]

  intercept ["start_game"]

  def join("room:"<> room_id, _message, socket) do
    pid = 
      case FakeArtist.GameSupervisor.create_game(room_id) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end
    player = FakeArtist.Player.new(FakeArtist.Game.Lists.artists |> Enum.random(), Enum.random(@colors))
    FakeArtist.GameServer.join(pid, player)
    socket = assign(socket, :game_state, FakeArtist.GameServer.get_state(pid))
    socket = assign(socket, :game_server_pid, pid)
    socket = assign(socket, :player, player)
    IO.inspect(socket)
    IO.inspect(pid)
    send(self(), :after_join)
    {:ok, [socket.assigns.game_state, player], socket}
  end
  def handle_info(:after_join, socket) do
    broadcast!(socket, "join", %{players: socket.assigns.game_state.players})
    {:noreply, socket}
  end
  def terminate(_reason, socket) do
    pid = socket.assigns.game_server_pid
    player = socket.assigns.player
    game_state = FakeArtist.GameServer.leave(pid, player)
    broadcast_from!(socket, "leave", %{players: game_state.players})
  end
  def handle_in("start_game", _message, socket) do
    pid = socket.assigns.game_server_pid
    game_state = FakeArtist.GameServer.start_game(pid)
    broadcast!(socket, "start_game", game_state)
    {:noreply, socket}
  end
  def handle_in("draw", %{"position" => position}, socket) do
    pid = socket.assigns.game_server_pid
    player = socket.assigns.player
    game_state = FakeArtist.GameServer.draw(pid, player, position)
    socket = assign(socket, :game_state, game_state)
    broadcast_from!(socket, "player_draw", %{player: player, position: position})
    {:noreply, socket}
  end
  def handle_in("mousedown", %{"position" => position}, socket) do
    pid = socket.assigns.game_server_pid
    player = socket.assigns.player
    game_state = FakeArtist.GameServer.mousedown(pid, player, position)
    socket = assign(socket, :game_state, game_state)
    broadcast_from!(socket, "player_mousedown", %{player: player, position: position})
    {:noreply, socket}
  end
  def handle_in("mouseup", %{}, socket) do
    pid = socket.assigns.game_server_pid
    game_state = FakeArtist.GameServer.mouseup(pid)
    socket = assign(socket, :game_state, game_state)
    broadcast!(socket, "next_turn", %{next_player: game_state.player_turn, status: game_state.status})
    IO.inspect(socket)
    {:noreply, socket}
  end
  def handle_in("change_name", new_name, socket) do
    pid = socket.assigns.game_server_pid
    updated_player = %FakeArtist.Player{socket.assigns.player | name: new_name }
    game_state = FakeArtist.GameServer.update_player(pid, updated_player)
    socket = assign(socket, :game_state, game_state)
    socket = assign(socket, :player, updated_player)
    broadcast!(socket, "join", %{players: socket.assigns.game_state.players})
    {:noreply, socket}
  end
  def handle_in("vote_fake", %{"player_index" => player_index}, socket) do
    pid = socket.assigns.game_server_pid
    voting_player = socket.assigns.player
    voted_player = Enum.at(socket.assigns.game_state.players, player_index)
    game_state = FakeArtist.GameServer.vote_fake(pid, voting_player, voted_player)
    IO.inspect(game_state)
    socket = assign(socket, :game_state, game_state)
    if game_state.status == :game_over do
      FakeArtist.GameServer.stop(pid)
      broadcast!(socket, "game_over", game_state)
    else
      broadcast!(socket, "vote_fake", %{votes: game_state.votes})
    end
    {:noreply, socket}
  end
  def handle_out("start_game", game_state, socket) do
    socket = assign(socket, :game_state, game_state)
    player = socket.assigns.player

    is_fake_artist = FakeArtist.Game.is_fake_artist(game_state, player)
    word = if(is_fake_artist, do: Map.put(game_state.word, :text, nil), else: game_state.word)

    modified_game_state = if(!is_fake_artist, do: Map.put(game_state, :fake_artist, nil), else: game_state)
    modified_game_state = Map.put(modified_game_state, :word, word)
    push(socket, "start_game", modified_game_state)
    {:noreply, socket}
  end
  
end

