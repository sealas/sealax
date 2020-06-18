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

    if tags[:authorized] do
      {:ok, user} = %User{}
      |> User.create_test_changeset(%{email: "some@email.com", password: "some password", active: true})
      |> Repo.insert()

      {:ok, %Account{} = account} = Account.create(user_id: user.id, appkey: "incredibly_encrypted_encryption_key")

      token_content = %{id: user.id, account_id: account.id}
      {:ok, token}  = AuthToken.generate_token(token_content)

      conn = conn
      |> Plug.Conn.put_req_header("authorization", "bearer: " <> token)

      {:ok, conn: conn, account: account, user: user, token: token}
    else
      {:ok, conn: conn}
    end
  end
end
