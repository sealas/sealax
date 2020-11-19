defmodule Sealax.Accounts.Workspace do
  use BaseModel, repo: Sealax.Repo
  import Ecto.Changeset
  alias Sealax.Accounts.User

  @primary_key {:id, WorkspaceHashId, read_after_writes: true}
  schema "workspaces" do
    field :name, :string

    belongs_to :user, User, foreign_key: :owner_id
    timestamps()
  end

  @doc """
  Changeset for create().
  """
  @spec create_changeset(map) :: %Ecto.Changeset{}
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:owner_id, :name])
    |> validate_required([:owner_id, :name])
  end

  @spec update_changeset(map, map) :: %Ecto.Changeset{}
  def update_changeset(model, params) do
    model
    |> cast(params, [:name])
  end
end
