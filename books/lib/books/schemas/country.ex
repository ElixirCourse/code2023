defmodule Books.Country do
  use Ecto.Schema

  import Ecto.Changeset

  schema "countries" do
    field(:name, :string)
    field(:code, :string)

    timestamps()
  end

  def changeset(%__MODULE__{} = country, attrs) do
    country
    |> cast(attrs, [:name, :code])
    |> validate_required([:name, :code])
    |> validate_length(:code, min: 2, max: 2)
    |> validate_length(:name, min: 4, max: 64)
    |> unique_constraint(:code)
    |> unique_constraint(:name)
    |> validate_code()
    |> validate_name()
  end

  defp validate_code(%Ecto.Changeset{valid?: false} = changeset), do: changeset

  defp validate_code(changeset) do
    code = get_field(changeset, :code)

    if code != String.upcase(code) do
      add_error(changeset, :code, "Country code has to be in uppercase!")
    else
      changeset
    end
  end

  defp validate_name(%Ecto.Changeset{valid?: false} = changeset), do: changeset

  defp validate_name(changeset) do
    name = get_field(changeset, :name)
    {first_letter, _} = String.next_grapheme(name)

    if first_letter != String.upcase(first_letter) do
      add_error(changeset, :name, "Country name has to start with uppercase letter!")
    else
      changeset
    end
  end
end
