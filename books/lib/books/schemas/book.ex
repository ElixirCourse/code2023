defmodule Books.Book do
  use Ecto.Schema

  alias Books.Author

  schema "books" do
    field(:isbn, :string)
    field(:title, :string)
    field(:description, :string)
    field(:author_name, :string)
    field(:year, :integer)
    field(:language, :string)

    many_to_many(:authors, Author, join_through: "authors_books")

    timestamps()
  end
end
