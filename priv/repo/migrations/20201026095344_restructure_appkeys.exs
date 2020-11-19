defmodule Sealax.Repo.Migrations.RestructureAppkeys do
  use Ecto.Migration

  def change do
    alter table(:user) do
      remove :appkey
      remove :appkey_salt
    end

    alter table(:user_otp) do
      add :workspace_id, references(:workspaces)
    end

    drop_if_exists index(:items, [:account_id])
    drop_if_exists index(:items, [:account_id, :deleted])
    drop_if_exists index(:items, [:account_id, :content_type])
    drop_if_exists index(:items, [:account_id, :workspace_id])
    
    alter table(:items) do
      remove :account_id
    end

    create index(:items, [:workspace_id])
    create index(:items, [:workspace_id, :deleted])
    create index(:items, [:workspace_id, :content_type])

    create index(:user_workspaces, [:workspace_id, :user_id])
  end
end
