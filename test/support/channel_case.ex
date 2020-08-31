defmodule SealaxWeb.ChannelCase do
  @moduledoc """
  This module defines the test case to be used by
  channel tests.

  Such tests rely on `Phoenix.ChannelTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use SealaxWeb.ChannelCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias Sealax.Repo
  alias Sealax.Accounts.User
  alias Sealax.Accounts.Account

  using do
    quote do
      # Import conveniences for testing with channels
      import Phoenix.ChannelTest
      import SealaxWeb.ChannelCase

      require Logger

      # The default endpoint for testing
      @endpoint SealaxWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Sealax.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Sealax.Repo, {:shared, self()})
    end

    setup = {:ok, %{}}

    if tags[:setup] do
      setup
      |> create_user(tags)
      |> auth_user(tags)
    else
      setup
    end
  end

  defp create_user({:ok, items}, %{:create_user => true}) do
    {:ok, %Account{} = account} = Account.create(name: "Test Account", slug: "test_account")

    {:ok, user} = %User{}
    |> User.create_test_changeset(%{email: "some@email.com", password: "some password", active: true, account_id: account.id, appkey: "encrypted_appkey"})
    |> Repo.insert()

    items = items
    |> Map.put(:account, account)
    |> Map.put(:user, user)

    {:ok, items}
  end
  defp create_user(setup, _), do: setup

  defp auth_user({:ok, items}, %{:auth_user => true}) do
    token_content = %{id: items.user.id, account_id: items.account.id}
    {:ok, token}  = AuthToken.generate_token(token_content)

    items = items
    |> Map.put(:token, token)

    {:ok, items}
  end
  defp auth_user(setup, _), do: setup
end
