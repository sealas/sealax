defmodule Sealax.Accounts.UserWorkspace do
  use BaseModel, repo: Sealax.Repo
  import Ecto.Changeset
  alias Sealax.Accounts.User
  alias Sealax.Accounts.Workspace
  alias Sealax.Accounts.UserWorkspace

  schema "user_workspaces" do
    field :appkey_salt, :string
    field :appkey,      :string

    belongs_to :user, User
    belongs_to :workspace, Workspace, type: WorkspaceHashId

    timestamps()
  end

  @doc """
  Changeset for create().
  """
  @spec create_changeset(map) :: %Ecto.Changeset{}
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:user_id, :workspace_id, :appkey, :appkey_salt])
    |> validate_required([:user_id, :workspace_id, :appkey, :appkey_salt])
  end

  defmodule Query do
    import Ecto.Query

    def get_all_from_user(user_id) do
      (from uw in UserWorkspace,
        join: w in assoc(uw, :workspace),
        select: %{
          appkey_salt: uw.appkey_salt,
          appkey: uw.appkey,
          workspace_id: uw.id,
          name: w.name
        },
        where: uw.user_id == ^user_id
      )
      |> Sealax.Repo.all
    end
  end
end
