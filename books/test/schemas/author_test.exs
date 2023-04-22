defmodule Books.AuthorTest do
  use Books.RepoCase

  alias Books.Author
  alias Books.Country

  test "can be created with a country" do
    changeset =
      Author.changeset(%Author{}, %{
        first_name: "Слави",
        last_name: "Боянов",
        birth_date: Date.from_iso8601!("1996-03-03"),
        country: %{name: "Bulgaria", code: "BG"}
      })

    %Author{} = author = Books.Repo.insert!(changeset)

    %Country{name: "Bulgaria", code: "BG"} = author.country

    changeset =
      Author.changeset(%Author{}, %{
        first_name: "Николай",
        last_name: "Цветинов",
        birth_date: Date.from_iso8601!("1984-05-04"),
        country: %{name: "Bulgaria", code: "BG"}
      })

    %Author{} = author = Books.Repo.insert!(changeset, on_conflict: :nothing)

    %Country{name: "Bulgaria", code: "BG", id: country_id} = author.country

    changeset =
      Author.changeset(%Author{}, %{
        first_name: "Иван",
        last_name: "Александров",
        birth_date: Date.from_iso8601!("1996-05-13"),
        country_id: country_id
      })

    %Author{} = author = Books.Repo.insert!(changeset, on_conflict: :nothing)
    author = Books.Repo.preload(author, :country)

    %Country{name: "Bulgaria", code: "BG", id: ^country_id} = author.country

    author_names =
      "Bulgaria"
      |> Author.by_country_name()
      |> Enum.map(& &1.name)
      |> Enum.sort()

    assert ["Иван Александров", "Николай Цветинов", "Слави Боянов"] == author_names
  end
end
