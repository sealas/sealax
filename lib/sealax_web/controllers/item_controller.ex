defmodule SealaxWeb.ItemController do
  use SealaxWeb, :controller

  alias SealaxWeb.Endpoint

  alias Sealax.Accounts.Item

  action_fallback SealaxWeb.FallbackController

  require Logger

  def index(conn, _params) do
    item = Item.where(account_id: conn.assigns.account_id)

    conn
    |> put_status(:ok)
    |> render("index.json", item: item)
  end

  def update(conn, %{"id" => id, "item" => params}) do
    case Item.SyncManager.sync(conn.assigns.account_id, id, params) do
      {:ok, item} ->
        Endpoint.broadcast("item:" <> conn.assigns.account_id, "update_item", %{item: item})

        conn
        |> put_status(:created)
        |> render("show.json", item: item)
      {:conflict, conflict} ->
        conn
        |> put_status(:bad_request)
        |> render("conflict.json", conflict: conflict)
    end
  end

  def create(conn, %{"item" => params}) do
    params = params
    |> Map.put("account_id", conn.assigns.account_id)

    case Item.create(params) do
      {:ok, %Item{} = item} ->
        Endpoint.broadcast("item:" <> conn.assigns.account_id, "new_item", %{item: item})

        conn
        |> put_status(:created)
        |> render("show.json", item: item)
      {:error, error} ->
        conn
        |> put_status(:bad_request)
        |> render("error.json", error: error)
    end
  end

  def delete(conn, %{"id" => id}) do
    case Item.delete_where(id: id, account_id: conn.assigns.account_id) do
      {:ok, 0} ->
        conn
        |> put_status(:bad_request)
        |> render("error.json", error: "cant_delete")
      {:ok, _} ->
        Endpoint.broadcast("item:" <> conn.assigns.account_id, "delete_item", %{id: id})

        conn
        |> put_status(:created)
        |> render("status.json", status: "ok")
    end
  end
end
