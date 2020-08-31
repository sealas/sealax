defmodule SealaxWeb.UserController do
  @moduledoc """
  Controller for all user actions
  """

  use SealaxWeb, :controller

  alias Sealax.Accounts.User
  alias Sealax.Accounts.Account

  action_fallback SealaxWeb.FallbackController

  @env Mix.env()

  defp env, do: @env

  def index(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:ok, "{\"yeah\": \"sure\"}")
  end

  def update(conn, %{"password" => password, "password_hint" => password_hint, "appkey" => appkey, "appkey_salt" => appkey_salt} = params) do
    # 
  end

  def update(conn, %{"otp" => otp, "device_hash" => device_hash} = params) do
    # 
  end
end
