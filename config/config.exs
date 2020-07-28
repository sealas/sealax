# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :sealax,
  ecto_repos: [Sealax.Repo]

# Configures the endpoint
config :sealax, SealaxWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "MEP0tuS7r27KVdUd8AjOmlcoWemGsl9CWy/8ei2tZMQBKRIiEA9I/5cEYz/ysw+p",
  render_errors: [view: SealaxWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: :sealax_pubsub,
  live_view: [signing_salt: "NuddYDVS"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

config :sealax, SealaxWeb.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  from: {"Sealas", "support@sealas.at"}#,
  # embedded_images: %{
  #   "logo" =>     "assets/sealas-logo-white-yellow.png",
  #   "twitter" =>  "assets/mail-twitter.png",
  #   "facebook" => "assets/mail-facebook.png",
  #   "github" =>   "assets/mail-github.png"
  # }
