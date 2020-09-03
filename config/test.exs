use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :sealax, Sealax.Repo,
  username: "postgres",
  password: "postgres",
  database: "sealax_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :sealax, SealaxWeb.Endpoint,
  http: [port: 4002],
  server: false,
  hash_salt: "test_hash_yes_yaw"

# Print only warnings and errors during test
config :logger, level: :warn

config :authtoken,
  token_key: <<137, 144, 234, 6, 5, 22, 168, 94, 77, 224, 206, 199, 91, 164, 37, 223>>

config :sealax, Sealax.Yubikey,
  skip_server: true

config :ex_unit,
  assert_receive_timeout: 1000

config :sealax,
  token_spam_time: [milliseconds: 500]
