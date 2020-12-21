# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :fake_artist, FakeArtistWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Wubx8XdN4ahSqavK1yIFP8qbSgFsym647esSU1XMk7yJhMTiGZYvtemIBozLi5CB",
  render_errors: [view: FakeArtistWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: FakeArtist.PubSub,
  live_view: [signing_salt: "/M8oAFFp"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
