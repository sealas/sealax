defmodule SealaxWeb.ItemChannelTest do
  use SealaxWeb.ChannelCase

  alias SealaxWeb.UserSocket
  alias SealaxWeb.ItemChannel

  alias Sealax.Accounts.Item

  @create_attrs %{
    "content_type" => "invoice",
    "content" => "encrypted_content"
  }

  describe "socket" do
    test "refuse connection without token or invalid token" do
      assert :error == connect(UserSocket, %{})
      assert :error == connect(UserSocket, %{"token" => "asdf"})
    end

    @tag setup: true, create_user: true, auth_user: true
    test "refuse connection for unauthorized channel", %{token: token} do
      assert {:ok, socket} = connect(UserSocket, %{"token" => token})

      assert {:error, %{reason: "unauthorized"}} = socket
      |> subscribe_and_join(ItemChannel, "item:1")
    end
  end

  describe "item channel" do
    @describetag setup: true, create_user: true, auth_user: true

    setup (context) do
      create = Map.put(@create_attrs, "account_id", context.account.id)
      {:ok, item} = Item.create(create)

      {:ok, socket} = connect(
        UserSocket,
        %{"token" => context.token}
      )
      {:ok, _, socket} = socket
      |> subscribe_and_join(ItemChannel, "item:" <> context.account.id)

      %{socket: socket, item: item}
    end

    test "get all items", %{socket: socket, account: account} do
      create = Map.put(@create_attrs, "account_id", account.id)
      
      Enum.each(1..100, fn _ -> Item.create(create) end)

      ref = push socket, "get_items", %{}

      assert_reply ref, :all_items, %{items: items, sync_token: sync_token}, 500000
      assert Enum.count(items) == 101
      refute is_nil(sync_token)

      Process.sleep(100)

      Enum.each(1..10, fn _ -> Item.create(create) end)

      ref = push socket, "get_items", %{sync_token: sync_token}

      assert_reply ref, :all_items, %{items: items, sync_token: sync_token}, 500000
      assert Enum.count(items) == 10
    end

    test "delete item", %{socket: socket, item: item} do
      ref = push socket, "delete_item", %{id: item.id}

      assert_reply ref, :delete_item_ok, %{id: id}
      assert_broadcast "delete_item", %{id: id}
      assert id == item.id

      ref = push socket, "delete_item", %{id: item.id}

      assert_reply ref, :error, %{id: id}
    end

    test "add item", %{socket: socket} do
      ref = push socket, "add_item", %{item: @create_attrs}

      assert_reply ref, :add_item_ok, %{id: id, updated_at: updated_at}
      assert_broadcast "add_item", %{item: item}
    end

    test "update item", %{socket: socket, item: item} do
      Process.sleep(1000)

      ref = push socket, "update_item", %{id: item.id, item: %{
        "content_type" => "new_type",
        "content" => "new_stuff",
        "updated_at" => item.updated_at,
        "id" => item.id
      }}

      assert_reply ref, :update_item_ok, %{id: id, updated_at: updated_at}
      assert_broadcast "update_item", %{item: updated_item}
      assert updated_item.id == item.id
      assert updated_item.updated_at != item.updated_at
    end

    test "update outdated item causes conflict", %{socket: socket, item: item} do
      ref = push socket, "update_item", %{id: item.id, item: %{
        "content_type" => "new_type",
        "content" => "new_stuff",
        "updated_at" => Timex.shift(item.updated_at, minutes: -300),
        "id" => item.id
      }}

      assert_reply ref, :error, %{conflict: %{type: type, server_item: updated_item}}

      assert type == "sync_conflict"
    end
  end
end
