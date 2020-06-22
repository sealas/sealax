defmodule Sealax.Repo.Migrations.SwitchAccountUser do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :account_id, references(:account)
      add :appkey,     :text
    end

    alter table(:account) do
      add    :name, :text
      remove :user_id
      remove :appkey
    end
  end
end
