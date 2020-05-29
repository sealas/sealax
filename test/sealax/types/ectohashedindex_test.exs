defmodule Sealax.EctoHashedIndexTest do
  use Sealax.DataCase

  @test_invoice_uuid "c13bbe22-f8f6-55a0-47af-313e82edfbbd"
  @test_invoice_uuid_binary <<193, 59, 190, 34, 248, 246, 85, 160, 71, 175, 49, 62, 130, 237, 251, 189>>

  describe "casting custom ecto hash type" do
    test "type is uuid" do
      assert EctoHashedIndex.type == Ecto.UUID
    end

    test "cast" do
      assert EctoHashedIndex.cast("test_invoice") == {:ok, @test_invoice_uuid}
    end

    test "cast uuid" do
      assert EctoHashedIndex.cast(@test_invoice_uuid) == {:ok, @test_invoice_uuid}
    end

    test "dump" do
      {:ok, hash} = EctoHashedIndex.cast("test_invoice")

      assert EctoHashedIndex.dump(hash) == {:ok, @test_invoice_uuid_binary}
    end

    test "load" do
      assert EctoHashedIndex.load(@test_invoice_uuid_binary) == EctoHashedIndex.cast("test_invoice")
    end
  end
end
