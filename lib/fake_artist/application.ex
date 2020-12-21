defmodule FakeArtist.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      FakeArtistWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: FakeArtist.PubSub},
      # Start the Endpoint (http/https)
      FakeArtistWeb.Endpoint,
      # Start a worker by calling: FakeArtist.Worker.start_link(arg)
      # {FakeArtist.Worker, arg}
      # Start de game registry
      {Registry, keys: :unique, name: FakeArtist.GameRegistry},
      FakeArtist.GameSupervisor,
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FakeArtist.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    FakeArtistWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
