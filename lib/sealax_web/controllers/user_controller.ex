defmodule SealaxWeb.UserController do
  @moduledoc """
  Controller for all user actions
  """

  use SealaxWeb, :controller

  alias Sealax.Accounts.User
  alias Sealax.Accounts.UserOTP
  # alias Sealax.Accounts.Account
  alias Sealax.Repo

  action_fallback SealaxWeb.FallbackController

  @env Mix.env()

  defp env, do: @env

  def index(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:ok, "{\"yeah\": \"sure\"}")
  end

  def create(conn, %{"password" => _password, "password_hint" => _password_hint, "appkey" => _appkey, "appkey_salt" => _appkey_salt} = params) do
    user = User.find(conn.assigns.user_id)

    changeset = User.update_password_changeset(user, params)

    case Repo.update(changeset) do
      {:error, error} ->
        conn
        |> render("error.json", error: error)
      {:ok, _user} ->
        conn
        |> render("status.json", status: "ok")
    end
  end

  def create(conn, %{"appkey" => _appkey, "device_hash" => _device_hash} = params) do
    user = User.find(conn.assigns.user_id)

    with {:ok, %UserOTP{}} <- UserOTP.create(params |> Map.put("user_id", user.id))
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
