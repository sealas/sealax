defmodule Sealax.Repo.Migrations.CreateUserOtp do
  use Ecto.Migration

  def change do
    create table(:user_otp) do
      add :appkey,      :string
      add :device_hash, :string
      
      add :user_id,     references(:user)

      timestamps()
    end
  end
end
