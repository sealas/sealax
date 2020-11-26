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
      |> TestData.create_user(tags)
      |> TestData.create_workspace(tags)
      |> TestData.auth_user(tags)
    else
      setup
    end
  end
end
