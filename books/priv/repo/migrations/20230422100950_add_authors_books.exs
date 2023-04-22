defmodule Books.Repo.Migrations.AddAuthorsBooks do
  use Ecto.Migration

  def change do
    create table(:authors_books) do
      add :author_id, references(:authors), null: false
      add :book_id, references(:books), null: false
    end
  end
end
