defmodule Sealax.Repo.Migrations.CreateAccount do
  use Ecto.Migration

  def change do
    create table(:account) do
      add :user_id,       references(:user)

      add :appkey,        :text
      add :slug,          :varchar, size: 64
      add :active,        :boolean, default: false
      add :installed,     :boolean, default: false
      add :account_info,  :map

      timestamps()
    end
  end
end
