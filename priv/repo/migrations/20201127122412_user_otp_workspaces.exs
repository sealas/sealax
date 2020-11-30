defmodule Sealax.Repo.Migrations.UserOtpWorkspaces do
  use Ecto.Migration

  def change do
    alter table(:user_otp) do
      remove :workspace_id
      remove :appkey

      add :workspace_keys, :map
    end
  end
end
