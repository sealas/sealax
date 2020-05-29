defmodule Sealax.Repo do
  use Ecto.Repo,
    otp_app: :sealax,
    adapter: Ecto.Adapters.Postgres
end
