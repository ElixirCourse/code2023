defmodule Books.Author do
  use Ecto.Schema

  alias Books.Book
  alias Books.Country
  alias Books.Repo

  import Ecto.Changeset
  import Ecto.Query

  schema "authors" do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:birth_date, :date)

    field(:name, :string, virtual: true)

    belongs_to(:country, Country)
    many_to_many(:books, Book, join_through: "authors_books")

    timestamps()
  end

  def changeset(%__MODULE__{} = author, %{country: country} = attrs) do
    author
    |> cast(attrs, [:first_name, :last_name, :birth_date])
    |> validate_required([:first_name, :last_name])
    |> check_country(country)
    |> validate()
  end

  def changeset(%__MODULE__{} = author, %{country_id: _} = attrs) do
    author
    |> cast(attrs, [:first_name, :last_name, :birth_date, :country_id])
    |> validate_required([:first_name, :last_name, :country_id])
    |> foreign_key_constraint(:country_id)
    |> validate()
  end

  defp validate(changeset) do
    changeset
    |> validate_length(:first_name, min: 1, max: 32)
    |> validate_length(:last_name, min: 1, max: 32)
  end

  defp check_country(%{valid?: false} = changeset, _), do: changeset

  defp check_country(changeset, country) do
    country_changeset = Country.changeset(%Country{}, country)

    if country_changeset.valid? do
      put_country(Repo.get_by(Country, name: get_field(country_changeset, :name)), changeset)
    else
      changeset
    end
  end

  defp put_country(nil, changeset) do
    cast_assoc(changeset, :country, required: true, with: &Books.Country.changeset/2)
  end

  defp put_country(country, changeset) do
    put_assoc(changeset, :country, country)
  end

  def by_country_name(country_name) do
    query =
      from(
        a in __MODULE__,
        join: c in Country,
        on: a.country_id == c.id,
        where: c.name == ^country_name,
        preload: [:country]
      )

    query =
      from(a in query, select_merge: %{name: fragment("? || ' ' || ?", a.first_name, a.last_name)})

    Repo.all(query)
  end
end
