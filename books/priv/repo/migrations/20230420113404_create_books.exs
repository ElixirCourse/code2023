defmodule Books.Repo.Migrations.CreateBooks do
  use Ecto.Migration

  def up do
    create table(:books) do
      add :isbn,        :string, size: 32
      add :title,       :string
      add :description, :string
      add :author_name, :string
      add :year,        :integer
      add :language,    :string

      timestamps()
    end
  end


  def down do
    drop table(:books)
  end
end
