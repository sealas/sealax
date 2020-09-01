defmodule Sealax.Accounts.UserOTP do
  use BaseModel, repo: Sealax.Repo
  import Ecto.Changeset

  alias Sealax.Accounts.User

  schema "user_otp" do
    field :appkey,      :string
    field :device_hash, :string

    belongs_to :user, User

    timestamps()
  end

  @doc """
  Changeset for create().
  """
  @spec create_changeset(map) :: %Ecto.Changeset{}
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:appkey, :device_hash, :user_id])
    |> validate_required([:appkey, :device_hash, :user_id])
  end
end
