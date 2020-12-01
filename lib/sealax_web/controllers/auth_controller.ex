defmodule SealaxWeb.AuthController do
  @moduledoc """
  Controller for all authentication actions:
  Default login, login with TFA, login with OTP and any other future ones.
  """

  use SealaxWeb, :controller

  alias Sealax.Accounts.User
  alias Sealax.Accounts.UserOTP
  alias Sealax.Accounts.UserTfa
  alias Sealax.Accounts.UserWorkspace

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
        token = generate_auth_token(user.id)

        conn
        |> put_status(:created) # http 201
        |> render("auth.json", %{token: token})

      # User exists, needs activation
      user && !user.active ->
        conn
        |> put_status(:bad_request)
        |> render("error.json", %{error: "inactive"})

      # invalid login, for which ever reason
      true ->
        conn
        |> put_status(:unauthorized) # http 401
        |> render("error.json", %{error: "auth_fail"})
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
         user when not is_nil(user) <- user
    do
      # Check if TFA key exists
      usertfa = Enum.find(user.tfa, fn tfa -> tfa.auth_key == key end)

      cond do
        {:auth, :ok} == UserTfa.validate_yubikey(auth_key) &&
        {:ok}        == tfa_match(user, usertfa)   ->
          User.update(user, recovery_code: nil)

          token = generate_auth_token(user.id)

          conn
          |> put_status(:created) # http 201
          |> render("auth.json", %{token: token})
        true ->
          conn
          |> put_status(:unauthorized) # http 401
          |> render("error.json", %{error: "auth_fail"})
      end
    else
      _ ->
      conn
      |> put_status(:unauthorized) # http 401
      |> render("error.json", %{error: "auth_fail"})
    end
  end

  def index(conn, %{"token" => auth_token, "workspace_id" => workspace_id}) do
    with {:ok, token} <- AuthToken.decrypt_token(auth_token),
         user         <- User.first(id: token["id"]),
         user when not is_nil(user) <- user,
         workspace <- UserWorkspace.Query.get_workspace(%{user_id: user.id, workspace_id: workspace_id}),
         workspace when not is_nil(workspace) <- workspace
    do
      {:ok, token} = AuthToken.generate_token(%{
        id: user.id,
        workspace_id: workspace.id
      })

      conn
      |> put_status(:created)
      |> render("auth.json", %{token: token, workspace_id: workspace.id, appkey: workspace.appkey, appkey_salt: workspace.appkey_salt})
    else
      _ ->
      conn
      |> put_status(:unauthorized) # http 401
      |> render("error.json", %{error: "auth_fail"})
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
          |> render("error.json", %{error: "auth_fail"})
      end
    else
      _ ->
      conn
      |> put_status(:unauthorized)
      |> render("error.json", %{error: "auth_fail"})
    end
  end

  @doc """
  Request for OTP login
  """
  def index(conn, %{"email" => email, "device_hash" => device_hash}) do
    with user <- User.first(email: email),
      user when not is_nil(user) <- user,
      otp <- UserOTP.first(user_id: user.id, device_hash: device_hash),
      otp when not is_nil(otp) <- otp,
      {:ok, token} <- User.user_token(user, %{id: user.id, device_hash: device_hash, otp_id: otp.id})
    do
      Phoenix.PubSub.broadcast(:sealax_pubsub, "user:otp_login", %{email: email, verification_code: token})

      conn
      |> put_status(:created)
      |> token_response(token)
    else
      e ->
        conn = conn
        |> put_status(:unauthorized)
        
        case e do
          {:error, :spam} ->
            render(conn, "error.json", %{error: "token_spam"})
          _ ->
            render(conn, "error.json", %{error: "auth_fail"})
        end
    end
  end

  def index(conn, %{"otp_token" => otp_token}) do
    with {:ok, decoded_token} <- Base.url_decode64(otp_token, padding: false),
         {:ok, token} <- AuthToken.decrypt_token(decoded_token),
         user         <- User.first(id: token["id"]),
         user when not is_nil(user) <- user,
         otp          <- UserOTP.find(token["otp_id"])
    do
      cond do
        token["updated_at"] == user.updated_at |> DateTime.to_unix(:microsecond) ->
          token = generate_auth_token(user.id)

          UserOTP.delete(otp.id)

          conn
          |> put_status(:created) # http 201
          |> render("auth.json", %{token: token, workspace_keys: otp.workspace_keys})
        true ->
          conn
          |> put_status(:unauthorized)
          |> render("error.json", %{error: "outdated_otp_token"})
      end
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render("error.json", %{error: "auth_fail"})
    end
  end

  defp generate_auth_token(user_id) do
    token_content = %{id: user_id}

    {:ok, token} = AuthToken.generate_token(token_content)

    token
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
