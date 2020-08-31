defmodule Sealax.UserControllerTest do
  use SealaxWeb.ConnCase

  alias Sealax.Accounts
  alias Sealax.Accounts.User

  @update_password %{password: "new_hashed_pw", password_hint: "guess it", appkey: "newly_encrypted_appkey", appkey_salt: "newly_generated_appkey_salt"}

  @add_otp %{otp: "encrypted_key", device_hash: "pew_pew"}

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "get 401 for protected route", %{conn: conn} do
    conn = post conn, Routes.user_path(conn, :create), @update_password

    assert json_response(conn, 401) == %{"error" => "auth_fail"}
  end

  describe "update user" do
    @describetag setup: true, create_user: true, auth_user: true

    test "update password", %{conn: conn} do
      conn = post conn, Routes.user_path(conn, :create), @update_password
  
      assert json_response(conn, 200) == %{"status" => "ok"}
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
