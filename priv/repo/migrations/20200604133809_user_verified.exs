defmodule Sealax.Repo.Migrations.UserVerified do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :verified, :boolean, default: false
    end
  end
end
