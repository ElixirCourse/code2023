defmodule Books.Repo.Migrations.RemoveAuthorNameFromBooks do
  use Ecto.Migration

  def change do
    alter table(:books) do
      remove :author_name
    end

    create unique_index(:authors, [:first_name, :last_name, :birth_date, :country_id])
  end
end
