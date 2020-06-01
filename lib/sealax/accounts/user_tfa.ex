defmodule Sealax.Accounts.UserTfa do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :type, :string
    field :auth_key, :string
  end

  def changeset(schema, params) do
    schema
    |> cast(params, [:type, :auth_key])
  end

  @doc """
  Validate a yubikey against the yubico API.
  If enable_test and the skip_server value in the config are true, it will always return a success.
  """
  @spec validate_yubikey(String.t, boolean) :: {:auth, :ok} | {:error, :no_yubico_credentials} | tuple
  def validate_yubikey(key, enable_test \\ true) do
    client_id   = Application.get_env(:sealax, Sealax.Yubikey)[:client_id]
    secret      = Application.get_env(:sealax, Sealax.Yubikey)[:secret]
    skip_server = Application.get_env(:sealax, Sealax.Yubikey)[:skip_server]

    cond do
      skip_server && enable_test ->
        {:auth, :ok}
      client_id && secret ->
        :yubico.simple_verify(key, client_id, secret, [])
      true ->
        {:error, :no_yubico_credentials}
    end
  end

  @doc """
  Extracts the key ID portion of a yubikey
  """
  @spec extract_yubikey(String.t) :: String.t
  def extract_yubikey(key) do
    {key, _auth} = String.split_at(key, -32)

    key
  end
end
