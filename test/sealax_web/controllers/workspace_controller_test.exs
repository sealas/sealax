defmodule Sealax.WorkspaceControllerTest do
  use SealaxWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "workspace actions" do
    @describetag setup: true, create_user: true, auth_user: true

    test "workspace flow", %{conn: conn} do
      conn = post conn, Routes.workspace_path(conn, :create), %{name: "Encrypted Workspace Name Goes Here", appkey: "encrypted_appkey", appkey_salt: "salty_salt"}
      assert auth = json_response(conn, 201)

      conn = get conn, Routes.workspace_path(conn, :index)
      assert %{"workspaces" => workspaces} = json_response(conn, 200)
      assert length(workspaces) == 1
    end
  end
end
