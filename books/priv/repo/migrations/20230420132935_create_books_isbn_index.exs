defmodule Books.Repo.Migrations.CreateBooksIsbnIndex do
  use Ecto.Migration

  def change do
    create unique_index(:books, [:isbn], name: :books_isbn_unique_idx)
  end
end
