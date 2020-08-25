defmodule Sealax.Repo.Migrations.MicrosecondTimestamps do
  use Ecto.Migration

  def change do
    alter table(:account) do
      modify :inserted_at, :utc_datetime_usec
      modify :updated_at, :utc_datetime_usec
    end
    alter table(:user) do
      modify :inserted_at, :utc_datetime_usec
      modify :updated_at, :utc_datetime_usec
    end
    alter table(:items) do
      modify :inserted_at, :utc_datetime_usec
      modify :updated_at, :utc_datetime_usec
    end
  end
end
