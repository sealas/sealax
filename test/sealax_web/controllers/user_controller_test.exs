defmodule Sealax.UserControllerTest do
  use SealaxWeb.ConnCase

  alias Sealax.Accounts
  alias Sealax.Accounts.User

  @create_attrs %{email: "some email"}
  @update_attrs %{email: "some updated email"}
  @invalid_attrs %{email: nil}

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "update user" do
    @describetag setup: true, create_user: true

    
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
