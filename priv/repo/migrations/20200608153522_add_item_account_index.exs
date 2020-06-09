defmodule Sealax.Repo.Migrations.AddItemAccountIndex do
  use Ecto.Migration

  def change do
    create index(:items, [:account_id])
    create index(:items, [:account_id, :deleted])
  end
end
