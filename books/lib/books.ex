defmodule Books do
  @moduledoc """
  Contains a few queeries related to books.
  """

  alias Books.Repo

  import Ecto.Query

  def books_by_year(year) do
    query =
      from("books",
        where: [year: ^year],
        select: [:title, :author_name]
      )

    Repo.all(query)
  end

  def books_by_years_or_authors(years, authors) do
    query =
      from(b in "books",
        where: b.year in ^years or b.author_name in ^authors,
        select: [:id, :isbn, :title, :author_name, :year, :description]
      )

    Repo.all(query)
  end

  def book_by_id(id) do
    query =
      from("books",
        where: [id: ^id],
        select: [:id, :title, :author_name, :year]
      )

    Repo.one(query)
  end

  def insert_book!(isbn, title, description, author_name, year, language) do
    {1, [%{id: id}]} =
      Repo.insert_all(
        "books",
        [
          [
            isbn: isbn,
            title: title,
            description: description,
            author_name: author_name,
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
end
