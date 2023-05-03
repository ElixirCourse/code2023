defmodule Books.Repo.Migrations.AddCountry do
  use Ecto.Migration

  def change do
    create table(:countries) do
      add :name, :string, size: 32, null: false
      add :code, :string, size: 2, null: false

      timestamps()
    end

    create unique_index(:countries, [:name])
    create unique_index(:countries, [:code])
  end
end
