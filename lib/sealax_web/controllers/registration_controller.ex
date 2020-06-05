defmodule SealaxWeb.RegistrationController do
  @moduledoc """
  Controller for all registration actions, including user verification
  """

  use SealaxWeb, :controller

  alias Sealax.Accounts.User
  alias Sealax.Accounts.Account

  action_fallback SealaxWeb.FallbackController

  @doc """
  Check if token is still valid
  """
  @spec show(Plug.Conn.t, %{id: String.t}) :: Plug.Conn.t
  def show(conn, %{"id" => token}) do
    with {:ok, token} <- Base.url_decode64(token),
      {:ok, content} <- AuthToken.decrypt_token(token)
    do
      case Timex.after?(Timex.now, Timex.from_unix(content["ct"]) |> Timex.shift(minutes: 300)) do
        false ->
          conn
          |> render("status.json", status: "ok")
        true ->
          conn
          |> put_status(:bad_request)
          |> render("status.json", status: "token_expired")
      end
    else
      err ->
      conn
      |> put_status(:bad_request)
      |> render("error.json", error: "wrong_code")
    end

    # cond do
    #   user && !user.verified ->
    #     conn
    #     |> render("code.json", email: user.email)
    #   true ->
    #     conn
    #     |> put_status(:bad_request)
    #     |> render("error.json", error: "wrong_code")
    # end
  end

  @doc """
  Verify user with provided code
  """
  @spec create(Plug.Conn.t, %{code: String.t, user: %{}}) :: Plug.Conn.t
  def create(conn, %{"code" => code, "user" => user_params}) do
    user = User.first(verification_code: code)

    cond do
      !user || user.verified ->
        conn
        |> put_status(:bad_request)
        |> render("error.json", error: "wrong_code")
      true ->
        with {:ok, %User{} = user} <- User.update(user, password: user_params["password"], password_hint: user_params["password_hint"], salt: user_params["salt"], verified: true, verification_code: nil),
          {:ok, %Account{} = account} <- Account.create(user: user, appkey: user_params["appkey"])
        do
          conn
          |> put_status(:created)
          |> render("status.json", status: "verify_token")
        else
          err -> conn
          |> put_status(:bad_request)
          |> render("error.json", error: err)
        end
    end
  end

  @doc """
  First step to registration, check email, broadcast verification code.
  """
  @spec create(Plug.Conn.t, %{email: string}) :: Plug.Conn.t
  def create(conn, %{"email" => email}) do
    user = User.first(email: email)

    cond do
      !user ->
        token = verification_token(email)

        Phoenix.PubSub.broadcast(Sealax.PubSub, "user:send_verification", %{email: email, verification_code: token})

        conn
        |> put_status(:created)
        |> render("status.json", status: "verify_token")
      user && !user.verified ->
        token = verification_token(email)

        Phoenix.PubSub.broadcast(Sealax.PubSub, "user:send_verification", %{email: email, verification_code: token})

        conn
        |> put_status(:bad_request)
        |> render("error.json", error: "retry_validation")
      true ->
        conn
        |> put_status(:bad_request) # http 400
        |> render("error.json", error: "already_registered")
    end
  end

  defp verification_token(email) do
    user_params = %{email: email}

    {:ok, token} = AuthToken.generate_token(user_params)

    token = Base.url_encode64(token)
  end
end
