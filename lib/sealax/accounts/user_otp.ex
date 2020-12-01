defmodule Sealax.Accounts.UserOTP do
  use BaseModel, repo: Sealax.Repo
  import Ecto.Changeset

  alias Sealax.Accounts.User
  alias Sealax.Accounts.UserOTP.WorkspaceKeys
  alias Sealax.Accounts.Workspace

  schema "user_otp" do
    field :device_hash, :string

    embeds_many :workspace_keys, WorkspaceKeys
    
    belongs_to :user, User

    timestamps()
  end

  @doc """
  Changeset for create().
  """
  @spec create_changeset(map) :: %Ecto.Changeset{}
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:device_hash, :user_id])
    |> cast_embed(:workspace_keys)
    |> validate_required([:device_hash, :user_id])
  end

  @spec update_changeset(map, map) :: %Ecto.Changeset{}
  def update_changeset(model, params) do
    model
    |> cast(params, [])
    |> cast_embed(:workspace_keys)
  end

  defmodule WorkspaceKeys do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :appkey, :string
      belongs_to :workspace, Workspace, type: WorkspaceHashId
    end
  
    def changeset(schema, params) do
      schema
      |> cast(params, [:appkey, :workspace_id])
    end
  end
end
