defmodule FakeArtist.GameServer do
  use GenServer
  alias FakeArtist.Game

  # Client (Public Interface)

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, %Game{}, name: {:via, Registry, {FakeArtist.GameRegistry, game_id}})
  end

  def draw(pid, player, draw_position) do
    GenServer.call(pid, {:draw, player, draw_position})
  end
  def mousedown(pid, player, draw_position) do
    GenServer.call(pid, {:mousedown, player, draw_position})
  end
  def mouseup(pid) do
    GenServer.call(pid, :mouseup)
  end
  def join(pid, player) do
    GenServer.call(pid, {:join, player})
  end
  def start_game(pid) do
    GenServer.call(pid, :start_game)
  end
  def leave(pid, player) do
    GenServer.call(pid, {:leave, player})
  end
  def update_player(pid, player) do
    GenServer.call(pid, {:update_player, player})
  end
  def vote_fake(pid, voting_player, voted_player) do
    GenServer.call(pid, {:vote_fake, voting_player, voted_player})
  end
  def stop(pid) do
    GenServer.stop(pid)
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  # Server (Callbacks)
  @impl true
  def init(_opts) do
    {:ok, %FakeArtist.Game{}}
  end

  @impl true
  def handle_call({:join, player}, _from, game) do
    game = Game.add_player(game, player)
    {:reply, game, game}
  end
  @impl true
  def handle_call(:start_game, _from, game) do
    game = Game.start(game)
    {:reply, game, game}
  end
  @impl true
  def handle_call({:leave, player}, _from, game) do
    game = Game.remove_player(game, player)
    {:reply, game, game}
  end

  @impl true
  def handle_call({:draw, player, draw_position}, _from, game) do
    game = Game.draw(game, player, draw_position)
    {:reply, game, game}
  end

  @impl true
  def handle_call({:mousedown, player, draw_position}, _from, game) do
    game = Game.draw(game, player, draw_position)
    {:reply, game, game}
  end

  @impl true
  def handle_call(:mouseup, _from, game) do
    game =
      game
      |> Game.end_curve()
      |> Game.next_turn()
    {:reply, game, game}
  end

  @impl true
  def handle_call({:update_player, player}, _from, game) do
    game = Game.update_player(game, player)
    {:reply, game, game}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:vote_fake, voting_player, voted_player}, _from, game) do
    game = Game.vote_fake(game, voting_player, voted_player)
    {:reply, game, game}
  end

  @impl true
  def handle_cast({:wipe, element}, state) do
    {:noreply, [element | state]}
  end
end
