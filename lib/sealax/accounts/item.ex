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

  def update_changeset(item, attrs) do
    item
    |> cast(attrs, [:content, :content_type, :deleted])
  end

  def sync_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:id])
    # |> validate_required([:account_id])
  end

  defmodule SyncManager do
    import Ecto.Query
    require Logger

    alias Sealax.Repo

    @min_conflict_interval 1.0

    def sync(conn, account_id, items, %{limit: limit, content_type: content_type} = _options) do
      retrieved_items = sync_get(account_id, limit, content_type)

      last_updated = DateTime.utc_now

      {saved_items, conflicts, retrieved_items} = sync_save(conn, account_id, items, retrieved_items)

      %{
        retrieved_items: retrieved_items,
        saved_items: saved_items,
        conflicts: conflicts
      }
    end

    defp sync_get(account_id, limit \\ 1000000, content_type \\ nil) do
      query = (from i in Item,
        where: i.account_id == ^account_id,
        where: i.deleted == false)

      query = cond do
        !is_nil(content_type) ->
          (from i in query,
            where: i.content_type == ^content_type)
        true -> query
      end

      items = Repo.all(from i in query, order_by: [desc: i.updated_at])

      count = (from i in query, select: count(i.id)) |> Repo.one()

      items
    end

    defp sync_save(_conn, _account_id, items, retrieved_items) when is_nil(items) or items == [], do: {[], [], retrieved_items}
    defp sync_save(conn, account_id, items, retrieved_items) do
      {saved_items, conflicts} = Enum.map_reduce(items, [], fn input_item, acc ->
        {item, is_new_record, conflict} = find_or_create(account_id, input_item)

        save_incoming = if !is_new_record do
          incoming_updated_at = case Map.get(input_item, "updated_at") do
            nil -> 0
            datetime -> DateTime.to_unix(datetime, :microsecond)
          end

          difference = incoming_updated_at - DateTime.to_unix(item.updated_at, :microsecond)

           cond do
            difference < 0 -> abs(difference) < @min_conflict_interval
            difference > 0 -> abs(difference) < @min_conflict_interval
            true -> true
          end
        end

        conflicts = case conflict do
          nil -> []
          conflict -> [conflict]
        end

        case save_incoming do
          false ->
            conflicts = [%{server_item: item, type: "sync_conflict"} | conflicts]

            {item, [conflicts | acc]}
          _ ->
            item = case item.deleted do
              true ->
                {:ok, deleted_item} = Item.update_changeset(item, %{
                  deleted: true,
                  content: nil,
                  enc_item_key: nil,
                  auth_hash: nil
                })
                |> Repo.update()

                deleted_item
              false -> item
            end

            {item, conflicts ++ acc}
        end
      end)

      retrieved_items = Enum.filter(retrieved_items, fn item ->
        Enum.find(conflicts, fn conflict -> conflict.server_item == item end) === nil
      end)

      {saved_items, conflicts, retrieved_items}
    end

    def find_or_create(account_id, input_item) do
      case Repo.get(Item, input_item["id"]) do
        nil ->
          changeset = Item.sync_changeset(%{id: input_item["id"], account_id: account_id})

          {item, conflict} = case Repo.insert(changeset) do
            {:ok, item} -> {item, nil}
            {:error, _} ->
              {%Item{}, %{unsaved_item: input_item, type: "id_conflict"}}
          end

          {item, true, conflict}
        item ->
          {item, false, nil}
      end
    end
  end
end
