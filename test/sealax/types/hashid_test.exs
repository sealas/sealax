defmodule Sealax.HashIdTest do
  use SealaxWeb.ConnCase

  defmodule TestHashId do
    use HashId, salt: "_test"
  end
  
  describe "hashid" do
    test "encode and decode produce reliable result" do
      assert {:error, :only_integer} = TestHashId.encode("pew")

      number = :rand.uniform(100_000_000)
      hash = TestHashId.encode(number)
      {:ok, decoded} = TestHashId.decode(hash)

      assert decoded == number

      assert {:error} = TestHashId.decode("BLBL" <> hash)
    end
  end
end
