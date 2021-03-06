defmodule Sealax.Accounts.User do
  use BaseModel, repo: Sealax.Repo
  use Ecto.Schema
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
    |> Base.url_encode64(padding: false)
    |> binary_part(0, length)
  end

  @doc """
  Create changeset for registration
  """
  @spec create_changeset(map) :: %Ecto.Changeset{}
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:email, :password, :password_hint, :settings, :account_id, :verified])
    |> validate_required([:email, :account_id])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 64, max: 256)
    |> unique_constraint(:email)
  end

  @spec update_changeset(map, map) :: %Ecto.Changeset{}
  def update_changeset(model, params) do
    model
    |> cast(params, [:settings, :verified, :active, :recovery_code])
    |> cast_embed(:tfa)
  end

  def update_password_changeset(%User{} = user, params) do
    user
    |> cast(params, [:password, :password_hint])
    |> validate_length(:password, min: 64, max: 256)
  end

  def token_changeset(%User{} = user, params) do
    user
    |> cast(params, [:updated_at])
  end

  @doc """
  Just for testing

  Only during testing do we ever need to create a user from a blob of hash attributes
  """
  @spec create_test_changeset(%User{}, map) :: %Ecto.Changeset{}
  def create_test_changeset(%User{} = user, params) do
    user
    |> cast(params, [:email, :password, :password_hint, :verified, :active, :settings, :account_id])
    |> cast_embed(:tfa)
  end

  def user_token(%User{} = user, token_content) do
    cond do
      nospam?(user) ->
        time = Timex.now

        user
        |> cast(%{updated_at: time}, [:updated_at])
        |> Sealax.Repo.update()

        {:ok, token} = token_content
        |> Map.put(:updated_at, time |> DateTime.to_unix(:microsecond))
        |> AuthToken.generate_token()

        {:ok, Base.url_encode64(token, padding: false)}
      true ->
        {:error, :spam}
    end
  end

  def nospam?(%User{} = user) do
    token_spam_time = Application.get_env(:sealax, :token_spam_time)

    Timex.after?(
      Timex.now,
      user.updated_at |> Timex.shift(token_spam_time)
    )
  end
end
