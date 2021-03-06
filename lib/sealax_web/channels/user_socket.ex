defmodule SealaxWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "item:*", SealaxWeb.ItemChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case AuthToken.decrypt_token(token) do
      {:ok, user} ->
        cond do
          token_valid?(user) ->
            {:ok, assign(socket, :user, user) |> assign(:token, token)}
          true ->
            :error
        end 
      _ ->
        :error
    end
  end
  @impl true
  def connect(_params, _socket, _connect_info), do: :error

  # Make sure token is actually an auth token.
  defp token_valid?(token) do
    is_nil(token["tfa_key"])
    && !is_nil(token["workspace_id"])
    && !AuthToken.is_timedout?(token)
    && !AuthToken.needs_refresh?(token)
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     SealaxWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user["id"]}"
end
