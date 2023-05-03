defmodule Books.Repo.Migrations.AddAuthorsBooks do
  use Ecto.Migration

  def change do
    create table(:authors_books) do
      add :author_id, references(:authors, on_delete: :delete_all), null: false
      add :book_id, references(:books, on_delete: :delete_all), null: false
    end
  end
end
