defmodule Books.Repo.Migrations.AddAuthor do
  use Ecto.Migration

  def change do
    create table(:authors) do
      add :first_name, :string, size: 32, null: false
      add :last_name,  :string, size: 32, null: false
      add :birth_date, :date
      add :country_id, references(:countries), null: false

      timestamps()
    end

    create index(:authors, [:first_name, :last_name])
  end
end
