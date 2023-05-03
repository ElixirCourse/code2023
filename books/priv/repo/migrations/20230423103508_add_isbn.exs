defmodule Books.Repo.Migrations.AddIsbn do
  use Ecto.Migration

  def up do
    create table(:international_standard_book_numbers) do
      add :book_id, references(:books, on_delete: :delete_all), null: false
      add :content, :map, null: false

      timestamps()
    end

    execute("CREATE UNIQUE INDEX isbn_content_idx ON international_standard_book_numbers((content->>'representation'));")
  end

  def down do
    execute("DROP INDEX isbn_content_idx")

    drop table(:international_standard_book_numbers)
  end
end
