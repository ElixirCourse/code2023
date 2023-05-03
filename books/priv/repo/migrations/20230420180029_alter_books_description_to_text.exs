defmodule Books.Repo.Migrations.AlterBooksDescriptionToText do
  use Ecto.Migration

  def up do
    alter table(:books) do
      modify :description, :text, null: false
    end
  end

  def down do
    alter table(:books) do
      modify :description, :string, null: true
    end
  end
end
