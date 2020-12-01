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

  def index(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:ok, "{\"yeah\": \"sure\"}")
  end

  @doc """
  Changing your password is a `create` action because we extract the user id from the token, not a URL param.
  """
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

  @doc """
  """
  def create(conn, %{"appkey" => appkey, "workspace_id" => workspace_id, "device_hash" => device_hash}) do
    user = User.find(conn.assigns.user_id)

    with user_otp <- UserOTP.first_or_create(%{user_id: user.id, device_hash: device_hash}),
      user_otp when not is_nil(user_otp) <- user_otp,
      cs <- UserOTP.update_changeset(user_otp, %{workspace_keys: [%{appkey: appkey, workspace_id: workspace_id} | user_otp.workspace_keys]}),
      _ <- Sealax.Repo.update(cs),
      cs when not is_nil(cs) <- cs
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
