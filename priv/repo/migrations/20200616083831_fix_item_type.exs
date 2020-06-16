defmodule Sealax.Repo.Migrations.FixItemType do
  use Ecto.Migration

  def change do
    alter table(:items) do
      remove :content_type
      add :content_type, :uuid, null: true
    end
  end
end
