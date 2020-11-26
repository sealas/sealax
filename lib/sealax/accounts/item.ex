defmodule Sealax.Accounts.Item do
  use BaseModel, repo: Sealax.Repo

  alias Sealax.Accounts.Item
  alias Sealax.Accounts.Workspace

  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]
  @primary_key {:id, ItemHashId, read_after_writes: true}
  schema "items" do
    field :content, :string
    field :content_type, EctoHashedIndex
    field :deleted, :boolean, default: false
    
    timestamps()
    
    belongs_to :workspace, Workspace, type: WorkspaceHashId
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:content, :content_type, :deleted, :workspace_id])
    |> validate_required([:workspace_id])
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:content, :content_type, :workspace_id])
    |> validate_required([:workspace_id])
  end

  def update_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:content, :content_type, :deleted])
  end

  defmodule Query do
    import Ecto.Query

    def get_all_with_token(workspace_id, sync_token) do
      sync_token = sync_token |> DateTime.from_unix!(:microsecond)
      
      query = get_all_query(workspace_id) |>
        where([i], i.updated_at > ^sync_token)

      Sealax.Repo.all(query)
    end

    def get_all(workspace_id) do
      query = get_all_query(workspace_id)

      Sealax.Repo.all(query)
    end

    defp get_all_query(workspace_id) do
      from i in Item,
        select: %{
          id: i.id,
          content: i.content,
          deleted: i.deleted,
          updated_at: i.updated_at
        },
        order_by: [desc: i.updated_at],
        where: i.workspace_id == ^workspace_id
    end
  end

  defmodule SyncManager do
    require Logger

    alias Sealax.Repo

    @min_conflict_interval 1.0

    def sync(workspace_id, item_id, item) do
      server_item = Item.first(workspace_id: workspace_id, id: item_id)

      incoming_updated_at = case Map.get(item, "updated_at") do
        nil -> 0
        datetime -> Timex.to_unix(datetime)
      end

      difference = incoming_updated_at - Timex.to_unix(server_item.updated_at)

      conflict =
        cond do
        difference != 0 -> abs(difference) > @min_conflict_interval
        true -> false
      end

      case !conflict do
        false ->
          {:conflict, %{server_item: server_item, type: "sync_conflict"}}
        _ ->
          case Map.get(item, "deleted") do
            true ->
              Item.update_changeset(server_item, %{
                deleted: true,
                content: nil
              })
              |> Repo.update()
            _ ->
              Item.update(server_item, item)
          end
      end
    end
  end
end
