defmodule SealaxWeb.WorkspaceView do
  use SealaxWeb, :view

  alias SealaxWeb.WorkspaceView

  def render("error.json", %{error: error}) do
    %{error: error}
  end

  def render("status.json", %{status: status}) do
    %{status: status}
  end

  def render("index.json", %{workspaces: workspaces}) do
    %{
      workspaces: render_many(workspaces, WorkspaceView, "workspace.json")
    }
  end

  def render("workspace.json", %{workspace: %{appkey: appkey, appkey_salt: appkey_salt, name: name, workspace_id: workspace_id}}) do
    %{
      appkey: appkey,
      appkey_salt: appkey_salt,
      name: name,
      workspace_id: WorkspaceHashId.encode(workspace_id)
    }
  end
end
