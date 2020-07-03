defmodule Sealax.RegistrationControllerTest do
  use SealaxWeb.ConnCase

  alias Sealax.Repo
  alias Sealax.Accounts.User
  alias Sealax.Accounts.Account

  @create_attrs %{email: "some@email.com", password: "some password", verified: true, appkey: "encrypted_appkey", appkey_salt: "salty_salt"}
  @create_unverified_attrs %{email: "some@email.com", password: "some password", verified: false, appkey: "encrypted_appkey", appkey_salt: "salty_salt"}

  @registration_attrs %{email: "some@email.com", password: "hashed password yall", password_hint: "so secret, mhhhh", appkey: "very encrypted key to your application", appkey_salt: "salty_salt"}
  @registration_attrs_2 %{email: "some.other@email.com", password: "hashed password yall", password_hint: "so secret, mhhhh", appkey: "very encrypted key to your application", appkey_salt: "salty_salt"}

  describe "verification" do
    test "get verification code as a new user", %{conn: conn} do
      @endpoint.subscribe("user:send_verification")

      conn = post conn, Routes.registration_path(conn, :create), email: @registration_attrs.email

      assert %{} = json_response(conn, 201)
      assert_receive %{email: _, verification_code: _}
    end

    test "get verification for an existing email", %{conn: conn} do
      {:ok, _user} = %User{}
        |> User.create_test_changeset(@create_attrs)
        |> Repo.insert()

      conn = post conn, Routes.registration_path(conn, :create), email: @registration_attrs.email

      assert %{"error" => "already_registered"} = json_response(conn, 400)
    end

    test "get verification for existing unvalidated email", %{conn: conn} do
      @endpoint.subscribe("user:send_verification")

      {:ok, _user} = %User{}
        |> User.create_test_changeset(@create_unverified_attrs)
        |> Repo.insert()

      conn = post conn, Routes.registration_path(conn, :create), email: @registration_attrs.email

      assert %{"error" => "retry_validation"} = json_response(conn, 400)
    end

    test "test verification code", %{conn: conn} do
      @endpoint.subscribe("user:send_verification")

      conn = post conn, Routes.registration_path(conn, :create), email: @registration_attrs.email

      assert_receive %{email: _, verification_code: token}

      conn = get conn, Routes.registration_path(conn, :show, token)

      assert %{"status" => "ok"} = json_response(conn, 200)

      conn = get conn, Routes.registration_path(conn, :show, "invalid token pew pew")

      assert %{"error" => "bad_token"} = json_response(conn, 400)
    end
  end

  describe "registration" do
    test "registration with valid parameters", %{conn: conn} do
      @endpoint.subscribe("user:send_verification")

      conn = post conn, Routes.registration_path(conn, :create), email: @registration_attrs.email

      assert_receive %{email: _, verification_code: token}

      conn = post conn, Routes.registration_path(conn, :create), %{token: token, user: @registration_attrs}

      assert %{"status" => "ok"} = json_response(conn, 201)

      account = Account.first(name: nil)
      conn = post conn, Routes.registration_path(conn, :create), email: @registration_attrs_2.email
      assert_receive %{email: _, verification_code: token}

      conn = post conn, Routes.registration_path(conn, :create), %{token: token, user: @registration_attrs_2, account_id: account.id}

      assert %{"status" => "ok"} = json_response(conn, 201)
    end

    test "registration with different email than token", %{conn: conn} do
      @endpoint.subscribe("user:send_verification")

      conn = post conn, Routes.registration_path(conn, :create), email: "no@u.com"

      assert_receive %{email: _, verification_code: token}

      conn = post conn, Routes.registration_path(conn, :create), %{token: token, user: @registration_attrs}

      assert %{"error" => "wrong_email"} = json_response(conn, 400)
    end
  end
end
