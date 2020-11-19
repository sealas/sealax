defmodule Sealax.Repo.Migrations.AddWorkspace do
  use Ecto.Migration

  def change do
    create table(:workspaces) do
      add :name, :string
      add :owner_id, references(:user), null: true

      timestamps()
    end

    alter table(:items) do
      add :workspace_id, references(:workspaces)
    end

    create index(:items, [:account_id, :workspace_id])
  end
end
