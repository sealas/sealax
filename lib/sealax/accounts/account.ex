defmodule Sealax.Accounts.Account do
  use BaseModel, repo: Sealax.Repo
  import Ecto.Changeset

  alias Sealax.Accounts.User

  @primary_key {:id, AccountHashId, read_after_writes: true}
  schema "account" do
    belongs_to :user, User

    field :appkey,        :string
    field :appkey_backup, :string
    field :slug,          :string
    field :active,        :boolean
    field :installed,     :boolean

    timestamps()
  end

  @doc """
  Changeset for create().
  """
  @spec create_changeset(map) :: %Ecto.Changeset{}
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:appkey, :user_id])
    |> validate_required([:appkey, :user_id])
  end
end
