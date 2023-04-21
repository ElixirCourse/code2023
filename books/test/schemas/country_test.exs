defmodule Books.CountryTest do
  use Books.RepoCase

  alias Books.Country

  test "doesn't crete countries with invalid code" do
    changeset = Country.changeset(%Country{}, %{name: "Bulgaria", code: "PRB"})

    refute changeset.valid?

    assert changeset.errors == [
             code:
               {"should be at most %{count} character(s)",
                [count: 2, validation: :length, kind: :max, type: :string]}
           ]

    changeset = Country.changeset(%Country{}, %{name: "Bulgaria", code: "bg"})

    refute changeset.valid?

    assert changeset.errors == [code: {"Country code has to be in uppercase!", []}]
  end

  test "doesn't crete countries with invalid name" do
    changeset = Country.changeset(%Country{}, %{name: "bulgaria", code: "BG"})

    refute changeset.valid?

    assert changeset.errors == [name: {"Country name has to start with uppercase letter!", []}]
  end

  test "inserting invalid country results in an error" do
    changeset = Country.changeset(%Country{}, %{name: "bulgaria", code: "BG"})

    {:error, _} = Repo.insert(changeset)
  end

  test "inserting a valid country works fine" do
    changeset = Country.changeset(%Country{}, %{name: "Bulgaria", code: "BG"})

    {:ok, %Country{name: "Bulgaria", code: "BG", inserted_at: _, updated_at: _}} =
      Repo.insert(changeset)
  end
end
