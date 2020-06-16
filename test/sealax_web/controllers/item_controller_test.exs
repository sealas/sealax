defmodule SealaxWeb.ItemControllerTest do
  use SealaxWeb.ConnCase

  alias Sealax.Accounts.Item

  require Logger

  @create_attrs %{
    "content_type" => "invoice",
    "content" => "encrypted_content"
  }

  describe "create items" do
    @describetag :authorized

    test "create with valid params", %{conn: conn} do
      conn = post conn, Routes.item_path(conn, :create), item: @create_attrs

      assert %{"item" => %{} = item} = json_response(conn, 201)
      assert item["content"] == @create_attrs["content"]
    end
  end

  describe "get and manipulate items" do
    @describetag :authorized
    setup [:create_item]

    test "get all items", %{conn: conn} do
      conn = get conn, Routes.item_path(conn, :index)

      assert %{"items" => items} = json_response(conn, 200)
      assert Enum.count(items) == 1
    end

    test "delete item", %{conn: conn, item: item} do
      conn = delete conn, Routes.item_path(conn, :delete, item.id)

      assert %{"status" => "ok"} == json_response(conn, 201)

      conn = delete conn, Routes.item_path(conn, :delete, item.id)

      assert %{"error" => "cant_delete"} == json_response(conn, 400)

      conn = delete conn, Routes.item_path(conn, :delete, 543453)

      assert %{"error" => "cant_delete"} == json_response(conn, 400)
    end

    test "update item", %{conn: conn, item: item} do
      conn = put conn, Routes.item_path(conn, :update, item.id), item: %{
        "content_type" => "new_type",
        "content" => "new_stuff",
        "updated_at" => item.updated_at,
        "id" => item.id
      }

      assert %{"item" => updated_item} = json_response(conn, 201)
      assert updated_item["id"] == item.id
      assert updated_item["updated_at"] != item.updated_at
    end

    test "update outdated item causes conflict", %{conn: conn, item: item} do
      conn = put conn, Routes.item_path(conn, :update, item.id), item: %{
        "content_type" => "new_type",
        "content" => "new_stuff",
        "updated_at" => Timex.shift(item.updated_at, minutes: -300),
        "id" => item.id
      }

      assert %{"type" => type, "server_item" => updated_item} = json_response(conn, 400)
      assert type == "sync_conflict"
    end
  end

  defp create_item(context) do
    create = Map.put(@create_attrs, "account_id", context.account.id)

    {:ok, item} = Item.create(create)

    {:ok, item: item}
  end
end
