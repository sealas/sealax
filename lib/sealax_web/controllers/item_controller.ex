defmodule SealaxWeb.ItemController do
  use SealaxWeb, :controller

  alias Sealax.Repo
  alias Sealax.Accounts.Item

  action_fallback SealaxWeb.FallbackController

  require Logger

  def index(conn, params) do
    account_id = get_account(conn)

    item = Item.where(account_id: account_id)

    conn
    |> put_status(:ok)
    |> render("index.json", item: item)
  end

  def update(conn, %{"id" => id, "item" => params}) do
    account_id = get_account(conn)

    Item.SyncManager.sync(account_id, params)
  end

  def create(conn, %{"item" => params}) do
    account_id = get_account(conn)

    params = params
    |> Map.put("account_id", account_id)

    case Item.create(params) do
      {:ok, %Item{} = item} ->
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
    account_id = get_account(conn)

    case Item.delete_where(id: id, account_id: account_id) do
      {:ok, 0} ->
        conn
        |> put_status(:bad_request)
        |> render("error.json", error: "cant_delete")
      {:ok, _} ->
        conn
        |> put_status(:created)
        |> render("status.json", status: "ok")
    end
  end

  defp get_account(conn) do
    {:ok, token} = AuthToken.decrypt_token(conn)

    token["account_id"]
  end
end
