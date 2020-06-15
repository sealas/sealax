defmodule Sealax.UserTfaTest do
  use Sealax.DataCase

  alias Sealax.Repo
  alias Sealax.Accounts.User
  alias Sealax.Accounts.UserTfa

  @create_user_attrs %{email: "some email", password: "some password"}

  @valid_attrs %{type: "yubikey", auth_key: "cccccccccccccccccccccccccccccccfilnhluinrjhl"}
  @invalid_attrs %{type: "yubikey", auth_key: nil}

  @test_yubikey "cccccccccccccccccccccccccccccccfilnhluinrjhl"

  describe "user tfa schema" do
    def user_fixture() do
      {:ok, user} = %User{}
        |> User.create_test_changeset(@create_user_attrs)
        |> Repo.insert()

      user
    end

    def tfa_fixture() do
      user_tfa_attrs = Map.put(@create_user_attrs, :tfa, [@valid_attrs])

      {:ok, user} = %User{}
        |> User.create_test_changeset(user_tfa_attrs)
        |> Repo.insert()
      user
    end
  end

  describe "yubikey functions" do
    # @tag external: true
    # test "validate_yubikey/1 runs check against server and fails" do
    #   assert {:bad_auth, :not_authentic_response} = UserTfa.validate_yubikey(@test_yubikey, false)
    # end

    test "validate_yubikey/1 runs check" do
      assert {:auth, :ok} = UserTfa.validate_yubikey(@test_yubikey)
    end

    test "extracts yubikey key" do
      assert "cccccccccccc" == UserTfa.extract_yubikey(@test_yubikey)
    end
  end
end
