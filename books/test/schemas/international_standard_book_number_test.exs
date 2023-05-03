defmodule Books.InternationalStandardBookNumberTest do
  use Books.RepoCase

  alias Books.InternationalStandardBookNumber, as: ISBNS
  alias Books.Types.ISBN

  import Ecto.Query

  test "it is saved as a map and loaded correctly" do
    {:ok, book_id} =
      Books.Repo.transaction(fn ->
        {:ok, %{id: country_id}} = Books.insert_or_get_country("USA", "US")

        {:ok, %{id: author_id}} =
          Books.insert_or_get_author(
            "Дан",
            "Симънс",
            Date.from_iso8601!("1948-04-04"),
            country_id
          )

        book_id = Books.insert_book!("978-619-152-344-3", "Ужас", "НЯМА", 2013, "български")
        :ok = Books.add_authors_to_book(book_id, [author_id])

        book_id
      end)

    changeset = ISBNS.changeset(%ISBNS{}, %{book_id: book_id, content: "978-619-152-344-3"})

    Books.Repo.insert!(changeset)

    query =
      from(i in ISBNS, where: fragment("content->>'representation' = ?", "978-619-152-344-3"))

    isbn = Books.Repo.one(query)

    refute is_nil(isbn)

    assert isbn.content == %ISBN{
             cn: 3,
             group: 619,
             id: 344,
             issuer: 152,
             prefix: 978,
             representation: "978-619-152-344-3"
           }
  end
end
