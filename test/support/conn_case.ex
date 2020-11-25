defmodule SealaxWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use SealaxWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias Sealax.Repo
  alias Sealax.Accounts.User
  alias Sealax.Accounts.Account

  @default_account %{name: "Test Account", slug: "test_account"}
  def default_account, do: @default_account
  @default_user %{email: "some@email.com", password: "some password", active: true, appkey: "encrypted_appkey"}
  def default_user, do: @default_user

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.ChannelTest
      import SealaxWeb.ConnCase

      alias SealaxWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint SealaxWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Sealax.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Sealax.Repo, {:shared, self()})
    end

    conn = Phoenix.ConnTest.build_conn()

    setup = {:ok, %{conn: conn}}

    if tags[:setup] do
      setup
      |> create_user(tags)
      |> auth_user(tags)
    else
      setup
    end
  end

  def create_user(setup, create_user, user \\ nil)
  def create_user({:ok, items}, %{:create_user => true}, user) do
    {:ok, %Account{} = account} = Account.create(@default_account)

    {:ok, user} = %User{}
    |> User.create_test_changeset((user || @default_user) |> Map.put(:account_id, account.id))
    |> Repo.insert()

    items = items
    |> Map.put(:account, account)
    |> Map.put(:user, user)

    {:ok, items}
  end
  def create_user(setup, _, _), do: setup

  def auth_user({:ok, items}, %{:auth_user => true}) do
    token_content = %{id: items.user.id, account_id: items.account.id}
    {:ok, token}  = AuthToken.generate_token(token_content)

    conn = items.conn
    |> Plug.Conn.put_req_header("authorization", "bearer: " <> token)

    items = items
    |> Map.put(:conn, conn)
    |> Map.put(:token, token)

    {:ok, items}
  end
  def auth_user(setup, _), do: setup
end
