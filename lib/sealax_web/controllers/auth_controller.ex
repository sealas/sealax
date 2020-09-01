defmodule SealaxWeb.AuthController do
  @moduledoc """
  Controller for all authentication actions:
  Default login, login with TFA, login with OTP and any other future ones.
  """

  use SealaxWeb, :controller

  alias Sealax.Accounts.Account
  alias Sealax.Accounts.User
  alias Sealax.Accounts.UserOTP
  alias Sealax.Accounts.UserTfa

  action_fallback SealaxWeb.FallbackController

  @env Mix.env()

  defp env, do: @env

  @doc """
  Login entry point for auth with email and password.
  Checks for any set TFA options
  """
  @spec index(Plug.Conn.t, %{email: String.t, password: String.t}) :: Plug.Conn.t
  def index(conn, %{"email" => email, "password" => password}) do
    user = User.first(email: email)

    cond do
      # Valid Login with TFA
      user && user.active && EctoHashedPassword.checkpw(password, user.password) && user.tfa != [] ->
        {:ok, token} = AuthToken.generate_token(%{
          id: user.id,
          tfa_token: true
        })

        conn
        |> put_status(:created) # http 201
        |> render("tfa.json", %{token: token})

      # Valid Login (no TFA)
      user && user.active && EctoHashedPassword.checkpw(password, user.password) ->
        account = Account.find(user.account_id)

        token_content = %{id: user.id, account_id: account.id}
        {:ok, token} = AuthToken.generate_token(token_content)

        conn
        |> put_status(:created) # http 201
        |> render("auth.json", %{token: token, account_id: account.id, appkey: user.appkey, appkey_salt: user.appkey_salt})

      # User exists, needs activation
      user && !user.active ->
        conn
        |> put_status(:bad_request)
        |> render("inactive.json")

      # invalid login, for which ever reason
      true ->
        conn
        |> put_status(:unauthorized) # http 401
        |> render("error.json")
    end
  end

  @doc """
  Entry for auth with TFA key.
  Requires token to identify user
  """
  @spec index(Plug.Conn.t, %{token: String.t, auth_key: String.t}) :: Plug.Conn.t
  def index(conn, %{"token" => token, "auth_key" => auth_key}) do
    key = UserTfa.extract_yubikey(auth_key)

    with {:ok, token} <- AuthToken.decrypt_token(token),
         user         <- User.first(id: token["id"]),
         user when not is_nil(user) <- user,
         account      <- Account.find(user.account_id)
    do
      # Check if TFA key exists
      usertfa = Enum.find(user.tfa, fn tfa -> tfa.auth_key == key end)

      cond do
        {:auth, :ok} == UserTfa.validate_yubikey(auth_key) &&
        {:ok}        == tfa_match(user, usertfa)   ->
          User.update(user, recovery_code: nil)

          token_content = %{id: user.id, account_id: account.id}
          {:ok, token}  = AuthToken.generate_token(token_content)

          conn
          |> put_status(:created) # http 201
          |> render("auth.json", %{token: token, account_id: account.id, appkey: user.appkey, appkey_salt: user.appkey_salt})
        true ->
          conn
          |> put_status(:unauthorized) # http 401
          |> render("error.json")
      end
    else
      _ ->
      conn
      |> put_status(:unauthorized) # http 401
      |> render("error.json")
    end
  end

  @doc """
  Refresh stale token
  """
  @dialyzer {:nowarn_function, index: 2}
  @spec index(Plug.Conn.t, %{token: String.t}) :: Plug.Conn.t
  def index(conn, %{"token" => auth_token}) do
    with {:ok, token} <- AuthToken.decrypt_token(auth_token),
         user         <- User.first(id: token["id"]),
         {:ok, token} <- AuthToken.refresh_token(auth_token)
    do
      cond do
        user && user.active && token ->
          conn
          |> put_status(:created)
          |> render("token.json", %{token: token})
        true ->
          conn
          |> put_status(:unauthorized)
          |> render("error.json")
      end
    else
      _ ->
      conn
      |> put_status(:unauthorized)
      |> render("error.json")
    end
  end

  def index(conn, %{"email" => email, "device_hash" => device_hash}) do
    with user <- User.first(email: email),
      otp <- UserOTP.first(user_id: user.id, device_hash: device_hash)
    do
      token = otp_token(email, device_hash)

      Phoenix.PubSub.broadcast(:sealax_pubsub, "user:otp_login", %{email: email, verification_code: token})

      conn
      |> put_status(:created)
      |> token_response(token)
    else
      _ ->
      conn
      |> put_status(:unauthorized)
      |> render("error.json")
    end
  end

  defp token_response(conn, token) do
    token_hash = :crypto.hash(:sha256, token)
    |> Base.encode16

    always_send_token = Application.get_env(:sealax, :always_send_token)

    token =
    cond do
      env() !== :prod || always_send_token -> token
      true -> ""
    end

    render(conn, "otp.json", status: "verify_token", token_hash: token_hash, token: token)
  end

  defp otp_token(email, device_hash) do
    user_params = %{email: email, device_hash: device_hash}

    {:ok, token} = AuthToken.generate_token(user_params)

    Base.url_encode64(token)
  end

  @doc """
  Checks for valid User and UserTFA entries and checks for a valid TFA key.
  """
  @spec tfa_match(%User{}, %UserTfa{}) :: {:ok} | {:error}
  defp tfa_match(user, usertfa) do
    cond do
      user && usertfa ->
        {:ok}
      true ->
        {:error}
    end
  end
end
