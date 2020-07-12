defmodule Sealax.AuthControllerTest do
  use SealaxWeb.ConnCase

  alias Sealax.Repo
  alias Sealax.Accounts.User
  alias Sealax.Accounts.Account

  @minimum_request_time 200_000

  @create_attrs %{email: "some@email.com", password: "some password", active: true, appkey: "encrypted_appkey"}
  @valid_login  %{email: "some@email.com", password: "some password"}
  @failed_login %{email: "some@email.com", password: "wrong password"}

  @create_tfa_attrs %{type: "yubikey", auth_key: "cccccccccccc"}
  @test_yubikey "cccccccccccccccccccccccccccccccfilnhluinrjhl"

  def fixture() do
    {:ok, %Account{} = account} = Account.create(name: "Test Account", slug: "test_account")

    {:ok, user} = %User{}
    |> User.create_test_changeset(@create_attrs |> Map.put(:account_id, account.id))
    |> Repo.insert()

    user
  end

  def fixture(:with_tfa) do
    user_tfa_attrs = @create_attrs |> Map.put(:tfa, [@create_tfa_attrs])

    {:ok, %Account{} = account} = Account.create(name: "Test Account", slug: "test_account")

    {:ok, user} = %User{}
    |> User.create_test_changeset(user_tfa_attrs |> Map.put(:account_id, account.id))
    |> Repo.insert()

    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "sso timing" do
    test "minimum request time", %{conn: conn} do
      time = Time.utc_now()

      post conn, Routes.auth_path(conn, :index), @failed_login

      diff = Time.diff(Time.utc_now(), time, :microsecond)
      assert diff >= @minimum_request_time
    end
  end

  describe "login" do
    setup [:create_user]

    test "successful authentication as a user", %{conn: conn} do
      conn = post conn, Routes.auth_path(conn, :index), @valid_login
      assert %{
        "token" => auth_token,
        "account_id" => account_id,
        "appkey" => appkey,
        "appkey_salt" => appkey_salt
      } = json_response(conn, 201)

      conn = conn
      |> recycle()
      |> put_req_header("authorization", "bearer: " <> auth_token)
      |> get(Routes.item_path(conn, :index))

      assert json_response(conn, 200)
    end

    test "fail to authenticate with wrong password", %{conn: conn} do
      conn = post conn, Routes.auth_path(conn, :index), @failed_login
      assert json_response(conn, 401) == %{"error" => "auth fail"}
    end

    test "get 401 for protected route", %{conn: conn} do
      conn = get conn, Routes.item_path(conn, :index)

      assert json_response(conn, 401) == %{"error" => "auth_fail"}
    end

    test "deny request with timedout token", %{conn: conn} do
      conn = post conn, Routes.auth_path(conn, :index), @valid_login
      assert %{
        "token" => auth_token,
        "account_id" => account_id,
        "appkey" => appkey,
        "appkey_salt" => appkey_salt
      } = json_response(conn, 201)

      {:ok, token} = AuthToken.decrypt_token(auth_token)
      {:ok, auth_token} = AuthToken.generate_token %{token | "ct" => DateTime.utc_now() |> DateTime.to_unix() |> Kernel.-(864000)}

      conn = conn
      |> recycle()
      |> put_req_header("authorization", "bearer: " <> auth_token)
      |> get(Routes.item_path(conn, :index))

      assert json_response(conn, 401) == %{"error" => "timeout"}
    end

    test "refresh stale token", %{conn: conn} do
      user = User.first(email: @valid_login.email)

      stale_token = create_stale_token(user)

      conn = conn
      |> recycle()
      |> put_req_header("authorization", "bearer: " <> stale_token)
      |> get(Routes.item_path(conn, :index))

      assert json_response(conn, 401) == %{"error" => "needs_refresh"}

      # Refresh token
      conn = post conn, Routes.auth_path(conn, :index), %{token: stale_token}
      assert %{
        "token" => auth_token,
        "account_id" => account_id,
        "appkey" => appkey,
        "appkey_salt" => appkey_salt
      } = json_response(conn, 201)

      # And retry request
      conn = conn
      |> recycle()
      |> put_req_header("authorization", "bearer: " <> auth_token)
      |> get(Routes.item_path(conn, :index))

      assert json_response(conn, 200)
    end

    test "refuse refreshing of token if user has been deleted or deactivated", %{conn: conn} do
      user = User.first(email: @valid_login.email)

      stale_token = create_stale_token(user)

      User.update(user, active: false)

      # Refresh token
      conn = post conn, Routes.auth_path(conn, :index), %{token: stale_token}
      assert json_response(conn, 401)

      User.delete(user)
      Account.delete(user.account_id)

      # Refresh token
      conn = post conn, Routes.auth_path(conn, :index), %{token: stale_token}
      assert json_response(conn, 401)
    end

    test "refuse refreshing of invalid tokens", %{conn: conn} do
      conn = post conn, Routes.auth_path(conn, :index), %{token: nil}
      assert json_response(conn, 401)

      conn = post conn, Routes.auth_path(conn, :index), %{token: "INVALID TOOOOOKEN"}
      assert json_response(conn, 401)
    end
  end

  describe "login with TFA" do
    setup [:create_user_with_tfa]

    test "successful authentication with TFA", %{conn: conn} do
      conn = post conn, Routes.auth_path(conn, :index), @valid_login
      assert %{"tfa" => true, "code" => tfa_code} = json_response(conn, 201)

      conn = post conn, Routes.auth_path(conn, :index), %{code: tfa_code, auth_key: @test_yubikey}
      assert %{
        "token" => _auth_token,
        "account_id" => _account_id,
        "appkey" => _appkey,
        "appkey_salt" => _appkey_salt
      } = json_response(conn, 201)
    end

    test "fail to authenticate with wrong password", %{conn: conn} do
      conn = post conn, Routes.auth_path(conn, :index), @failed_login
      assert json_response(conn, 401) == %{"error" => "auth fail"}
    end

    test "failed authentication with TFA", %{conn: conn} do
      conn = post conn, Routes.auth_path(conn, :index), @valid_login
      assert %{"tfa" => true, "code" => tfa_code} = json_response(conn, 201)

      conn = post conn, Routes.auth_path(conn, :index), %{code: "wrong code!", auth_key: "wrong key!"}
      assert json_response(conn, 401) == %{"error" => "auth fail"}

      conn = post conn, Routes.auth_path(conn, :index), %{code: tfa_code, auth_key: "wrong key!"}
      assert json_response(conn, 401) == %{"error" => "auth fail"}
    end
  end

  describe "unvalidated user" do
    test "fail to authenticate with unvalidated user", %{conn: conn} do
      {:ok, _user} = %User{}
      |> User.create_test_changeset(%{email: "email", password: "password", active: false})
      |> Repo.insert()

      conn = post conn, Routes.auth_path(conn, :index), %{email: "email", password: "password"}
      assert %{"error" => "inactive"} = json_response(conn, 400)
    end
  end

  defp create_user(_) do
    user = fixture()
    {:ok, user: user}
  end

  defp create_user_with_tfa(_) do
    user = fixture(:with_tfa)
    {:ok, user: user}
  end

  defp create_stale_token(user) do
    content = %{"id" => user.id, "rt" => DateTime.utc_now() |> DateTime.to_unix() |> Kernel.-(3600)}
    {:ok, auth_token} = AuthToken.generate_token(content)

    auth_token
  end
end
