defmodule Books.InternationalStandardBookNumber do
  use Ecto.Schema

  alias Books.Types.ISBN

  import Ecto.Changeset

  schema "international_standard_book_numbers" do
    field(:content, ISBN)

    belongs_to(:book, Books.Book)

    timestamps()
  end

  def changeset(%__MODULE__{} = international_standard_book_number, attrs) do
    international_standard_book_number
    |> cast(attrs, [:book_id, :content])
    |> validate_required([:book_id, :content])
  end
end
