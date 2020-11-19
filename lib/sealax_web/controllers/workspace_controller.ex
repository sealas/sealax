defmodule SealaxWeb.WorkspaceController do
  @moduledoc """
  Controller for all user actions
  """

  use SealaxWeb, :controller

  alias Sealax.Accounts.Workspace
  alias Sealax.Accounts.UserWorkspace
  alias Sealax.Accounts.User
  alias Sealax.Repo

  action_fallback SealaxWeb.FallbackController

  def index(conn, _params) do
    workspaces = UserWorkspace.Query.get_all_from_user(conn.assigns.user_id)

    conn
    |> render("index.json", workspaces: workspaces)
  end

  def create(conn, %{"name" => name, "appkey" => appkey, "appkey_salt" => appkey_salt} = _params) do
    user = User.find(conn.assigns.user_id)

    with {:ok, workspace}        <- Workspace.create(%{"name" => name, "owner_id" => user.id}),
         {:ok, %UserWorkspace{}} <- UserWorkspace.create(%{"workspace_id" => workspace.id, "user_id" => user.id, "appkey" => appkey, "appkey_salt" => appkey_salt})
    do
      conn
      |> put_status(:created)
      |> render("status.json", status: "ok")
    else
      err -> conn
      |> put_status(:bad_request)
      |> render("error.json", error: err)
    end
  end

  def update(conn, %{"name" => _name} = params) do
    user = User.find(conn.assigns.user_id)

    with {:ok, %Workspace{}} <- Workspace.update_where(params, owner_id: user.id)
    do
      conn
      |> render("status.json", status: "ok")
    else
      err -> conn
      |> put_status(:bad_request)
      |> render("error.json", error: err)
    end
  end
end
