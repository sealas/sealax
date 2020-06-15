defmodule Sealax.Accounts.Item do
  use BaseModel, repo: Sealax.Repo
  alias Sealax.Accounts.Account
  alias Sealax.Accounts.Item

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, ItemHashId, read_after_writes: true}
  schema "items" do
    field :content, :string
    field :content_type, EctoHashedIndex
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

  def update_changeset(item, attrs) do
    item
    |> cast(attrs, [:content, :content_type, :deleted])
  end

  defmodule SyncManager do
    import Ecto.Query
    require Logger

    alias Sealax.Repo

    @min_conflict_interval 1.0

    def sync(account_id, item) do
      server_item = Item.first(account_id: account_id, id: item.id)

      incoming_updated_at = case Map.get(item, :updated_at) do
        nil -> 0
        datetime -> Timex.to_unix(datetime)
      end

      difference = incoming_updated_at - Timex.to_unix(item.updated_at)

      conflict =
        cond do
        difference < 0 -> abs(difference) < @min_conflict_interval
        difference > 0 -> abs(difference) < @min_conflict_interval
        true -> false
      end

      case !conflict do
        false ->
          {:conflict, %{server_item: server_item, type: "sync_conflict"}}
        _ ->
          item = case item.deleted do
            true ->
              {:ok, deleted_item} = Item.update_changeset(server_item, %{
                deleted: true,
                content: nil
              })
              |> Repo.update()

              deleted_item
            false -> Item.update(server_item, item)
          end

          {:ok}
      end
    end
  end
end
