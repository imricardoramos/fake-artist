defmodule FakeArtist.Game do
  alias FakeArtist.Player
  @derive {Jason.Encoder, exclude: []}
  defstruct [
    players: [],
    current_curve: %{author: nil, points: []},
    curves: [],
    player_turn: nil,
    status: :in_lobby,
    round: 0,
    max_rounds: 2,
    fake_artist: nil,
    category: nil,
    word: nil,
    votes: %{},
    winner: nil,
    chat: []
  ]
  def add_player(game, %Player{} = player) do
    players = game.players ++ [player]
    game |> Map.replace!(:players, players)
  end
  def remove_player(game, %Player{} = player) do
    players = Enum.reject(game.players, fn item -> item == player end)
    game |> Map.replace!(:players, players)
  end
  def update_player(game, %Player{} = player) do
    player_index = Enum.find_index(game.players, fn item -> item.id == player.id end)
    players = List.replace_at(game.players, player_index, player)
    game |> Map.replace!(:players, players)
  end
  def is_fake_artist(game, %Player{} = player) do
    player.id == game.fake_artist
  end

  def draw(game, %Player{} = player, position) do
    game
    |> Map.put(:current_curve, %{author: player, points: [position | game.current_curve.points]})
  end

  def end_curve(game) do
    game
    |> Map.put(:curves, [game.current_curve | game.curves])
    |> Map.put(:current_curve, %{author: nil, points: []})
  end

  def start(game) do
    players = Enum.reverse(game.players)
    fake_artist = Enum.random(game.players)
    word = FakeArtist.Game.Lists.words |> Enum.random()
    
    game
      |> Map.replace!(:status, :playing)
      |> Map.replace!(:players, players)
      |> Map.replace!(:player_turn, 0)
      |> Map.replace!(:round, 1)
      |> Map.replace!(:fake_artist, fake_artist.id)
      |> Map.replace!(:word, word)
  end

  def next_turn(game) do
    next_player = rem(game.player_turn + 1, number_of_players(game))
    next_round = 
      if next_player == 0 do
        game.round + 1
      else
        game.round
      end
    if next_round > game.max_rounds do
      game
      |> Map.replace!(:status, :voting)
    else
      game
      |> Map.replace!(:player_turn, next_player)
      |> Map.replace!(:round, next_round)
    end

  end

  def number_of_players(game), do: Enum.count(game.players)
  def votes_count(game), do: Enum.count(Map.keys(game.votes))

  def vote_fake(game, %Player{} = accusing_player, %Player{} = accused_player) do
    accusing_index = Enum.find_index(game.players, fn player -> player == accusing_player end)
    accused_index = Enum.find_index(game.players, fn player -> player == accused_player end)
    votes =
      game.votes
      |> Map.put(accusing_index, accused_index)
    game = game |> Map.replace!(:votes, votes)

    if votes_count(game) == number_of_players(game) do
      terminate(game)
    else
      game
    end
  end

  def add_chat_msg(game, msg) do
    game
    |> Map.put(:chat, [msg | game.chat])
  end

  def terminate(game) do
    accused =
      game.players
      |> Enum.map(fn player ->
        {player, Enum.count(game.votes, fn {_accuser, accused} ->
          accused = Enum.at(game.players, accused)
          accused == player
        end)}
      end)
      |> Enum.max_by(fn tuple -> elem(tuple, 1) end)
      |> elem(0)

    if accused.id == game.fake_artist do
      game
      |> Map.replace!(:status, :game_over)
      |> Map.replace!(:winner, :real_artists)
    else
      game
      |> Map.replace!(:status, :game_over)
      |> Map.replace!(:winner, :fake_artist)
    end
  end
end
