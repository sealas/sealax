defmodule Sealax.Accounts.Account do
  use BaseModel, repo: Sealax.Repo
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]
  @primary_key {:id, AccountHashId, read_after_writes: true}
  schema "account" do
    field :name,          :string
    field :slug,          :string
    field :active,        :boolean
    field :installed,     :boolean

    timestamps()
  end

  @doc """
  Changeset for create().
  """
  @spec create_changeset(map) :: %Ecto.Changeset{}
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:slug, :name])
  end
end
