defmodule Sealax.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:user) do
      add :email,                :string
      add :password,             :string
      add :password_hint,        :string
      add :password_backup,      :string
      add :password_hint_backup, :string
      add :recovery_code,        :char, size: 32
      add :settings,             :map
      add :tfa,                  :map
      add :active,               :bool, default: true

      timestamps()
    end

    create unique_index(:user, [:email])
  end
end
