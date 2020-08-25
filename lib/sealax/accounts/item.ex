defmodule Sealax.Accounts.Item do
  use BaseModel, repo: Sealax.Repo
  alias Sealax.Accounts.Account
  alias Sealax.Accounts.Item

  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]
  @primary_key {:id, ItemHashId, read_after_writes: true}
  schema "items" do
    field :content, :string
    field :content_type, EctoHashedIndex
    # field :content_index, EctoHashedIndex
    field :deleted, :boolean, default: false

    timestamps()

    belongs_to :account, Account, type: AccountHashId
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:content, :content_type, :deleted, :account_id])
    |> validate_required([:account_id])
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:content, :content_type, :account_id])
    |> validate_required([:account_id])
  end

  def update_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:content, :content_type, :deleted])
  end

  defmodule Query do
    import Ecto.Query

    def get_all_by_account_with_token(account_id, sync_token) do
      sync_token = sync_token |> DateTime.from_unix!(:microsecond)
      
      query = get_all_query(account_id) |>
        where([i], i.updated_at > ^sync_token)

      Sealax.Repo.all(query)
    end

    def get_all_by_account(account_id) do
      query = get_all_query(account_id)

      Sealax.Repo.all(query)
    end

    defp get_all_query(account_id) do
      from i in Item,
        select: %{
          id: i.id,
          content: i.content,
          deleted: i.deleted,
          updated_at: i.updated_at
        },
        order_by: [desc: i.updated_at],
        where: i.account_id == ^account_id
    end
  end

  defmodule SyncManager do
    require Logger

    alias Sealax.Repo

    @min_conflict_interval 1.0

    def sync(account_id, item_id, item) do
      server_item = Item.first(account_id: account_id, id: item_id)

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
