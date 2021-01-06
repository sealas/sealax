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
         {:ok, user_workspace} <- UserWorkspace.create(%{"workspace_id" => workspace.id, "user_id" => user.id, "appkey" => appkey, "appkey_salt" => appkey_salt})
    do
      conn
      |> put_status(:created)
      |> render("workspace.json", workspace: %{appkey: user_workspace.appkey, appkey_salt: user_workspace.appkey_salt, name: workspace.name, workspace_id: user_workspace.workspace_id})
    else
      err -> conn
      |> put_status(:bad_request)
      |> render("error.json", error: err)
    end
  end

  def update(conn, %{"id" => id, "name" => name} = params) do
    user = User.find(conn.assigns.user_id)

    case Workspace.update_where(%{owner_id: user.id, id: id}, %{name: name}) do
      {:ok, 1} ->
        conn
        |> render("status.json", status: "ok")
      {:ok, 0} ->
        conn
        |> put_status(:bad_request)
        |> render("error.json", error: "no_update")
    end
  end
end
