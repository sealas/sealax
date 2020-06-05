defmodule Sealax.RegistrationControllerTest do
  use SealaxWeb.ConnCase

  import Swoosh.TestAssertions

  alias Sealax.Repo
  alias Sealax.Accounts.User

  @create_attrs %{email: "some@email.com", password: "some password", verified: true}
  @create_unverified_attrs %{email: "some@email.com", password: "some password", verified: false}

  @registration_attrs %{email: "some@email.com", password: "hashed password yall", password_hint: "so secret, mhhhh", appkey: "very encrypted key to your application"}

  describe "verification" do
    test "get verification code as a new user", %{conn: conn} do
      @endpoint.subscribe("user:send_verification")

      conn = post conn, Routes.registration_path(conn, :create), email: @registration_attrs.email

      assert %{} = json_response(conn, 201)
      assert_receive %{email: _, verification_code: _}
    end

    test "get verification for an existing email", %{conn: conn} do
      {:ok, user} = %User{}
        |> User.create_test_changeset(@create_attrs)
        |> Repo.insert()

      conn = post conn, Routes.registration_path(conn, :create), email: @registration_attrs.email

      assert %{"error" => "already_registered"} = json_response(conn, 400)
    end

    test "get verification for existing unvalidated email", %{conn: conn} do
      @endpoint.subscribe("user:send_verification")

      {:ok, user} = %User{}
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

      assert %{"error" => "wrong_code"} = json_response(conn, 400)
    end
  end
end
