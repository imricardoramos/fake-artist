defmodule FakeArtist.GameSupervisor do
  use DynamicSupervisor

  def start_link(_init_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def create_game(id) do
    DynamicSupervisor.start_child(__MODULE__, {FakeArtist.GameServer, id})
  end
  def current_games() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(&game_data/1)
  end

  defp game_data({_id, pid, _type, _modules}) do
    FakeArtist.GameServer.get_state(pid)
  end
end
