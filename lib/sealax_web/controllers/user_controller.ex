defmodule SealaxWeb.UserController do
  @moduledoc """
  Controller for all user actions
  """

  use SealaxWeb, :controller

  alias Sealax.Accounts.User
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

  def create(conn, %{"password" => password, "password_hint" => password_hint, "appkey" => appkey, "appkey_salt" => appkey_salt} = params) do
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

  def create(conn, %{"otp" => otp, "device_hash" => device_hash} = params) do
    #
  end
end
