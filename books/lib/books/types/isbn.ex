defmodule Books.Types.ISBN do
  use Ecto.Type

  defstruct [:prefix, :group, :issuer, :id, :cn, :representation]

  def type, do: :map

  def cast(:any, term), do: {:ok, term}
  def cast(term), do: {:ok, term}

  def load(%{
        "cn" => cn,
        "group" => group,
        "id" => id,
        "issuer" => issuer,
        "prefix" => prefix,
        "representation" => representation
      }) do
    {:ok,
     %__MODULE__{
       cn: cn,
       group: group,
       id: id,
       issuer: issuer,
       prefix: prefix,
       representation: representation
     }}
  end

  def load(_), do: :error

  def dump(%__MODULE__{
        prefix: prefix,
        group: group,
        id: id,
        issuer: issuer,
        cn: cn,
        representation: representation
      }) do
    {:ok,
     %{
       prefix: prefix,
       group: group,
       issuer: issuer,
       id: id,
       cn: cn,
       representation: representation
     }}
  end

  def dump(isbn) when is_binary(isbn) do
    if String.valid?(isbn) do
      dump_strings(String.split(isbn, "-"), isbn)
    else
      :error
    end
  end

  def dump(_), do: :error

  defp dump_strings(list, representation) when is_list(list) do
    ints =
      list
      |> Enum.map(&Integer.parse/1)
      |> Enum.map(fn
        {n, ""} -> n
        _ -> :error
      end)

    if Enum.any?(ints, fn v -> v == :error end) do
      :error
    else
      dump_ints(ints, representation)
    end
  end

  defp dump_strings(_, _), do: :error

  defp dump_ints([prefix, group, issuer, id, cn], representation) do
    {:ok,
     %{
       prefix: prefix,
       group: group,
       issuer: issuer,
       id: id,
       cn: cn,
       representation: representation
     }}
  end

  defp dump_ints([prefix, issuer, id, cn], representation) do
    {:ok,
     %{
       prefix: prefix,
       group: nil,
       issuer: issuer,
       id: id,
       cn: cn,
       representation: representation
     }}
  end

  defp dump_ints(_, _), do: :error
end
