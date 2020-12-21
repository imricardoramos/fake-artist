defmodule FakeArtist.Player do
  @derive {Jason.Encoder, only: [:id, :name, :color]}
  defstruct [:id, :name, :color]
  def new(name, color) do
    %FakeArtist.Player{id: UUID.uuid4(), name: name, color: color}
  end
end
