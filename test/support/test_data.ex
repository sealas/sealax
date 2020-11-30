defmodule TestData do
  alias Sealax.Repo
  alias Sealax.Accounts.User
  alias Sealax.Accounts.Account
  alias Sealax.Accounts.Workspace
  alias Sealax.Accounts.UserWorkspace

  @default_account %{name: "Test Account", slug: "test_account"}
  def default_account, do: @default_account
  
  @default_user %{email: "default@user.test", password: "some password", active: true}
  def default_user, do: @default_user

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

  def create_workspace(setup, create_workspace, workspace \\ nil)
  def create_workspace({:ok, items}, %{:create_workspace => true}, workspace) do
    {:ok, workspace} = Workspace.create(workspace || %{name: "Encrypted Workspace Name", owner_id: items.user.id})
    {:ok, user_workspace} = UserWorkspace.create(%{workspace_id: workspace.id, user_id: items.user.id, appkey: "Encrypted Appkey", appkey_salt: "Appkey Salt"})

    items = items
    |> Map.put(:workspace, workspace)
    |> Map.put(:user_workspace, user_workspace)

    {:ok, items}
  end
  def create_workspace(setup, _, _), do: setup

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
