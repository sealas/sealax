defmodule HashId do
  @moduledoc """
  Ecto type for indexing hash values as UUIDs in Postgres
  """
  defmacro __using__(opts) do
    salt = Keyword.get(opts, :salt)

    quote do
      use Ecto.Type
      def type, do: :integer

      @doc """
      """
      def cast(hashid) when is_binary(hashid), do: {:ok, hashid}
      def cast(id), do: Ecto.Type.cast(:integer, id)

      def load(id) when is_integer(id) and id > 0, do: {:ok, encode(id)}
      def load(_), do: :error

      def dump(hashid) when is_binary(hashid) do
        {:ok, id} = decode(hashid)

        {:ok, List.last(id)}
      end
      def dump(id), do: Ecto.Type.dump(:integer, id)

      def encode(id) do
        s = Hashids.new([
          min_len: 8,
          salt: Application.get_env(:sealax, SealaxWeb.Endpoint)[:hash_salt] <> unquote(salt)
        ])

        Hashids.encode(s, id)
      end

      def decode(hashid) do
        s = Hashids.new([
          min_len: 8,
          salt: Application.get_env(:sealax, SealaxWeb.Endpoint)[:hash_salt] <> unquote(salt)
        ])

        Hashids.decode(s, hashid)
      end
    end
  end
end
