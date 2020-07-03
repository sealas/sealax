defmodule Sealax.Repo.Migrations.AddUsersalt do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :appkey_salt, :text
    end
  end
end
