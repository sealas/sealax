defmodule Sealax.Item do
  use BaseModel, repo: Sealax.Repo
  alias Sealax.User
  alias Sealax.Item

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:uuid, :binary_id, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "items" do
    field :content, :string
    field :content_type, :string
    field :enc_item_key, :string
    field :auth_hash, :string
    field :deleted, :boolean, default: false
    field :last_user_agent, :string

    timestamps()

    belongs_to :user, User, foreign_key: :user_uuid, references: :uuid
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:content, :content_type, :enc_item_key, :auth_hash, :deleted, :last_user_agent, :user_uuid])
    |> validate_required([:user_uuid])
  end

  def update_changeset(item, attrs) do
    item
    |> cast(attrs, [:content, :content_type, :enc_item_key, :auth_hash, :deleted, :last_user_agent, :user_uuid])
  end

  def sync_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:uuid])
    # |> validate_required([:user_uuid])
  end

  defmodule SyncManager do
    import Ecto.Query
    require Logger

    alias Sealax.Repo

    @min_conflict_interval 1.0

    def sync(conn, user_uuid, items, %{sync_token: input_sync_token, cursor_token: input_cursor_token, limit: limit, content_type: content_type} = _options) do
      {retrieved_items, cursor_token} = sync_get(user_uuid, input_sync_token, input_cursor_token, limit, content_type)

      last_updated = DateTime.utc_now

      {saved_items, conflicts, retrieved_items} = sync_save(conn, user_uuid, items, retrieved_items)

      sync_token = cond do
        Enum.count(saved_items) > 0 ->
          Enum.sort(saved_items, &(DateTime.to_unix(&1.updated_at, :microsecond) <= DateTime.to_unix(&2.updated_at, :microsecond)))
          |> List.last
          |> Map.get(:updated_at)
        true ->
          last_updated
      end
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.add(1, :microsecond)
      |> sync_token_from_datetime()

      %{
        retrieved_items: retrieved_items,
        saved_items: saved_items,
        conflicts: conflicts,
        sync_token: sync_token,
        cursor_token: cursor_token
      }
    end

    defp sync_get(user_uuid, input_sync_token, input_cursor_token, limit \\ 1000000, content_type \\ nil) do
      query = (from i in Item,
        where: i.user_uuid == ^user_uuid)

      query = cond do
        !is_nil(input_cursor_token) ->
          date = datetime_from_sync_token(input_cursor_token)
          (from i in query,
            where: i.updated_at >= ^date)
        !is_nil(input_sync_token) ->
          date = datetime_from_sync_token(input_sync_token)
          (from i in query,
            where: i.updated_at > ^date)
        true ->
          (from i in query,
            where: i.deleted == false)
      end

      query = cond do
        !is_nil(content_type) ->
          (from i in query,
            where: i.content_type == ^content_type)
        true -> query
      end

      items = Repo.all(from i in query, order_by: [desc: i.updated_at])

      count = (from i in query, select: count(i.uuid)) |> Repo.one()

      cursor_token = cond do
        count > limit ->
          List.last(items)
          |> Map.get(:updated_at)
          |> sync_token_from_datetime()
        true -> nil
      end

      {items, cursor_token}
    end

    defp sync_save(_conn, _user_uuid, items, retrieved_items) when is_nil(items) or items == [], do: {[], [], retrieved_items}
    defp sync_save(conn, user_uuid, items, retrieved_items) do
      {saved_items, conflicts} = Enum.map_reduce(items, [], fn input_item, acc ->
        {item, is_new_record, conflict} = find_or_create(user_uuid, input_item)

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
            {:ok, item} = Item.update_changeset(item, %{last_user_agent: get_user_agent(conn)})
            |> Repo.update()

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

    def find_or_create(user_uuid, input_item) do
      case Repo.get(Item, input_item["uuid"]) do
        nil ->
          changeset = Item.sync_changeset(%{uuid: input_item["uuid"], user_uuid: user_uuid})

          {item, conflict} = case Repo.insert(changeset) do
            {:ok, item} -> {item, nil}
            {:error, _} ->
              {%Item{}, %{unsaved_item: input_item, type: "uuid_conflict"}}
          end

          {item, true, conflict}
        item ->
          {item, false, nil}
      end
    end

    defp get_user_agent(conn) do
      user_agent = Enum.find(conn.req_headers, fn({header, _value}) ->
        String.downcase(header) == "user-agent"
      end)

      case user_agent do
        {_, last_user_agent} -> last_user_agent
        _ -> nil
      end
    end

    defp sync_token_from_datetime(datetime) do
      version = 2
      microtime = DateTime.to_unix(datetime, :microsecond)
      Base.encode64("#{version}:#{microtime}")
    end

    defp datetime_from_sync_token(sync_token) do
      {:ok, decoded} = Base.decode64(sync_token)
      parts = String.split(decoded, ":")

      version = List.first(parts)
      timestamp = List.last(parts) |> String.replace(".", "") |> String.to_integer()

      case version do
        "1" -> ""
        "2" -> DateTime.from_unix!(timestamp, :microsecond)
      end
    end
  end
end
