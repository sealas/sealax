defmodule Sealax.UserControllerTest do
  use SealaxWeb.ConnCase

  @update_password %{password: "new_hashed_pw", password_hint: "guess it", appkey: "newly_encrypted_appkey", appkey_salt: "newly_generated_appkey_salt"}

  @add_otp %{appkey: "encrypted_key", device_hash: "pew_pew"}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "get 401 for protected route", %{conn: conn} do
    conn = post conn, Routes.user_path(conn, :create), @update_password

    assert json_response(conn, 401) == %{"error" => "auth_fail"}
  end

  describe "update user" do
    @describetag setup: true, create_user: true, auth_user: true

    test "update password and verify auth", %{conn: conn, user: user} do
      conn = post conn, Routes.auth_path(conn, :index), %{email: TestData.default_user().email, password: TestData.default_user().password}
      assert auth = json_response(conn, 201)

      conn = post conn, Routes.user_path(conn, :create), @update_password
      assert json_response(conn, 200) == %{"status" => "ok"}

      conn = post conn, Routes.auth_path(conn, :index), %{email: user.email, password: @update_password.password}
      assert auth = json_response(conn, 201)

      conn = post conn, Routes.auth_path(conn, :index), %{email: TestData.default_user().email, password: TestData.default_user().password}
      assert auth = json_response(conn, 401)
    end

    test "add otp and verify auth", %{conn: conn} do
      Process.sleep(500)
      conn = post conn, Routes.user_path(conn, :create), @add_otp
      assert json_response(conn, 200) == %{"status" => "ok"}

      conn = post conn, Routes.auth_path(conn, :index), %{email: TestData.default_user().email, device_hash: @add_otp.device_hash}
      assert %{"status" => status, "token" => token, "token_hash" => token_hash} = json_response(conn, 201)

      conn = post conn, Routes.auth_path(conn, :index), %{email: TestData.default_user().email, device_hash: @add_otp.device_hash}
      assert json_response(conn, 401) == %{"error" => "token_spam"}
      
      conn = post conn, Routes.auth_path(conn, :index), %{otp_token: token}
      assert %{"token" => token} = json_response(conn, 201)
    end
  end
end
