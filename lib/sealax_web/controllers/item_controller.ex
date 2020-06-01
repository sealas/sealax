defmodule SealaxWeb.ItemController do
  use SealaxWeb, :controller

  alias Sealax.Accounts.Item

  action_fallback SealaxWeb.FallbackController

  def sync(conn, params) do
    options = %{
      sync_token: params["sync_token"],
      cursor_token: params["cursor_token"],
      limit: params["limit"],
      content_type: params["content_type"],
    }

    user_uuid = ""

    results = Item.SyncManager.sync(conn, user_uuid, params["items"], options)
  end

  def create(conn, params) do
    #
  end

  def destroy(conn, id) do
    #
  end
end
