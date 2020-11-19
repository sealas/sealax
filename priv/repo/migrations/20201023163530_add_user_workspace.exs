defmodule Sealax.Repo.Migrations.AddUserWorkspace do
  use Ecto.Migration

  def change do
    create table(:user_workspaces) do
      add :appkey,      :string
      add :appkey_salt, :string

      add :user_id, references(:user)
      add :workspace_id, references(:workspaces)

      timestamps()
    end
  end
end
