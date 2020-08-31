use Mix.Config

# Configure your database
config :sealax, Sealax.Repo,
  username: "postgres",
  password: "postgres",
  database: "sealax_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :sealax, SealaxWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [],
  hash_salt: "FxikmS5zS6,DhX}sY"

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :authtoken,
  token_key: <<252, 147, 111, 145, 15, 42, 108, 134, 48, 196, 220, 22, 188, 184, 68, 11>>
