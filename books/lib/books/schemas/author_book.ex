defmodule Books.AuthorBook do
  use Ecto.Schema

  schema "authors_books" do
    belongs_to(:author, Books.Author)
    belongs_to(:book, Books.Book)
  end
end
