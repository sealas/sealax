defmodule Sealax.Repo.Migrations.CreateItem do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :content, :text
      add :content_type, :string
      add :deleted, :boolean, default: false
      add :last_user_agent, :text

      add :account_id, references(:account)

      timestamps()
    end

    create index(:items, [:account_id, :content_type])
  end
end
