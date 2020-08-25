defmodule Sealax.Accounts.User do
  use BaseModel, repo: Sealax.Repo
  import Ecto.Changeset

  alias Sealax.Accounts.User
  alias Sealax.Accounts.UserTfa
  alias Sealax.Accounts.Account

  @timestamps_opts [type: :utc_datetime_usec]

  @doc """
  We only identify users by email. Note that password and password_backup
  are cryptographic hashes, not the original entry!
  """
  schema "user" do
    belongs_to :account, Account, type: AccountHashId

    embeds_many :tfa, UserTfa

    field :email,                :string
    field :password,             EctoHashedPassword
    field :password_hint,        :string
    # field :password_backup,      EctoHashedPassword
    # field :password_hint_backup, :string
    field :appkey_salt,          :string
    field :appkey,               :string
    field :recovery_code,        :string
    field :settings,             :map
    field :active,               :boolean
    field :verified,             :boolean

    timestamps()
  end

  @doc """
  Create a random string of characters
  For use as a password or activation/recovery code. Or anything else, really.
  """
  @spec create_random_password(integer) :: String.t
  def create_random_password(length \\ 16) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64
    |> binary_part(0, length)
  end

  @doc """
  Create changeset for registration
  """
  @spec create_changeset(map) :: %Ecto.Changeset{}
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:email, :password, :password_hint, :settings, :appkey, :appkey_salt, :account_id, :verified])
    |> validate_required([:email, :appkey, :appkey_salt, :account_id])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end

  @spec update_changeset(map, map) :: %Ecto.Changeset{}
  def update_changeset(model, params) do
    model
    |> cast(params, [:password, :password_hint, :settings, :verified, :active, :recovery_code, :appkey, :appkey_salt])
    |> cast_embed(:tfa)
  end

  @doc """
  Just for testing

  Only during testing do we ever need to create a user from a blob of hash attributes
  """
  @spec create_test_changeset(%User{}, map) :: %Ecto.Changeset{}
  def create_test_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :password, :password_hint, :verified, :active, :settings, :appkey, :account_id, :appkey_salt])
    |> cast_embed(:tfa)
  end
end
