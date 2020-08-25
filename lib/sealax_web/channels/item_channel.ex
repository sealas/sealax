defmodule SealaxWeb.ItemChannel do
  use SealaxWeb, :channel

  alias Sealax.Accounts.Item

  require Logger

  def join("item:" <> account_id, _payload, %{assigns: %{user: user}} = socket) do
    cond do
      account_id == user["account_id"] ->
        case check_token(user) do
          {:ok} ->
            send(self(), :after_join)
            {:ok, socket}
          {:error, reason} ->
            {:error, %{reason: reason}}
        end
      true ->
        {:error, %{reason: "unauthorized"}}
    end
  end

  defp check_token(token) do
    cond do
      !is_nil(token["tfa_key"]) || is_nil(token["account_id"]) ->
        {:error, :invalid_token}
      AuthToken.is_timedout?(token) ->
        {:error, :timeout}
      AuthToken.needs_refresh?(token) ->
        {:error, :needs_refresh}
      true ->
        {:ok}
    end
  end

  # Retrieve all items
  def handle_info(:after_join, %{assigns: %{user: user}} = socket) do
    items = Item.where(account_id: user["account_id"])

    push socket, "all_items", SealaxWeb.ItemView.render("index.json", item: items)

    {:noreply, socket}
  end

  def handle_in("add_item", %{"item" => params}, %{assigns: %{user: user}} = socket) do
    params = params
    |> Map.put("account_id", user["account_id"])

    case Item.create(params) do
      {:ok, %Item{} = item} ->
        broadcast_from socket, "add_item", SealaxWeb.ItemView.render("show.json", item: item)

        {:reply, {:add_item_ok, %{id: item.id, updated_at: item.updated_at}}, socket}
      {:error, error} ->
        {:reply, {:error, error}, socket}
    end
  end

  def handle_in("update_item", %{"id" => id, "item" => params}, %{assigns: %{user: user}} = socket) do
    case Item.SyncManager.sync(user["account_id"], id, params) do
      {:ok, item} ->
        broadcast_from socket, "update_item", SealaxWeb.ItemView.render("show.json", item: item)

        {:reply, {:update_item_ok, %{id: item.id, updated_at: item.updated_at}}, socket}
      {:conflict, conflict} ->
        {:reply, {:error, %{conflict: conflict}}, socket}
    end
  end

  def handle_in("delete_item", %{"id" => id}, %{assigns: %{user: user}} = socket) do
    case Item.delete_where(id: id, account_id: user["account_id"]) do
      {:ok, 0} ->
        {:reply, {:error, %{id: id}}, socket}
      {:ok, _} ->
        broadcast_from socket, "delete_item", %{id: id}

        {:reply, {:delete_item_ok, %{id: id}}, socket}
    end
  end
end
