defmodule Books do
  @moduledoc """
  Contains a few queeries related to books.
  """

  alias Books.Author
  alias Books.AuthorBook
  alias Books.Country
  alias Books.Repo

  import Ecto.Query

  def books_by_year(year) do
    query =
      from(b in "books",
        join: ab in "authors_books",
        on: ab.book_id == b.id,
        join: a in "authors",
        on: ab.author_id == a.id,
        where: [year: ^year],
        select: [:title],
        select_merge: %{author_name: fragment("? || ' ' || ?", a.first_name, a.last_name)}
      )

    Repo.all(query)
  end

  def books_by_years_or_authors(years, authors) do
    {first_names, last_names} =
      Enum.reduce(authors, {[], []}, fn author_name, {fns, lns} ->
        [first_name, last_name] = String.split(author_name, " ", strip: true)
        {[first_name | fns], [last_name | lns]}
      end)

    query =
      from(b in "books",
        join: ab in "authors_books",
        on: ab.book_id == b.id,
        join: a in "authors",
        on: ab.author_id == a.id,
        where: b.year in ^years or (a.first_name in ^first_names and a.last_name in ^last_names),
        select: [:id, :isbn, :title, :year, :description],
        select_merge: %{author_name: fragment("? || ' ' || ?", a.first_name, a.last_name)}
      )

    Repo.all(query)
  end

  def book_by_id(id) do
    query =
      from(b in "books",
        join: ab in "authors_books",
        on: ab.book_id == b.id,
        join: a in "authors",
        on: ab.author_id == a.id,
        where: [id: ^id],
        select: [:id, :title, :year],
        select_merge: %{author_name: fragment("? || ' ' || ?", a.first_name, a.last_name)}
      )

    Repo.one(query)
  end

  def insert_book!(isbn, title, description, year, language) do
    {1, [%{id: id}]} =
      Repo.insert_all(
        "books",
        [
          [
            isbn: isbn,
            title: title,
            description: description,
            year: year,
            language: language,
            inserted_at: DateTime.utc_now(),
            updated_at: DateTime.utc_now()
          ]
        ],
        returning: [:id]
      )

    id
  end

  def update_book_description!(book_id, description) do
    query = from(b in "books", where: b.id == ^book_id)

    {1, _} = Repo.update_all(query, set: [description: description])
  end

  def delete_book_by_isbn!(isbn) do
    query = from(b in "books", where: b.isbn == ^isbn)

    {1, _} = Repo.delete_all(query)
  end

  def insert_or_get_country(name, code) do
    Repo.insert(
      Country.changeset(%Country{}, %{name: name, code: code}),
      on_conflict: :nothing,
      returning: true
    )
    |> case do
      {:ok, %Country{id: nil}} ->
        {:ok, Repo.get_by(Country, code: code, name: name)}

      any ->
        any
    end
  end

  def insert_or_get_author(first_name, last_name, birth_date, country_id) do
    Repo.insert(
      Author.changeset(%Author{}, %{
        last_name: last_name,
        first_name: first_name,
        birth_date: birth_date,
        country_id: country_id
      }),
      on_conflict: :nothing,
      # on_conflict: [set: [first_name: first_name]]
      returning: true
    )
    |> case do
      {:ok, %Author{id: nil}} ->
        {:ok,
         Repo.get_by(Author,
           first_name: first_name,
           last_name: last_name,
           birth_date: birth_date,
           country_id: country_id
         )}

      any ->
        any
    end
  end

  def add_authors_to_book(book_id, author_ids) do
    steps =
      Enum.reduce(author_ids, Ecto.Multi.new(), fn author_id, steps ->
        name = "step_#{book_id}_#{author_id}"
        Ecto.Multi.insert(steps, name, %AuthorBook{book_id: book_id, author_id: author_id})
      end)

    case Repo.transaction(steps) do
      {:ok, _} ->
        :ok

      {:error, _, changeset, _changes_so_far} ->
        {:error, changeset}
    end
  end
end
