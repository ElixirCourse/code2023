defmodule BooksTest do
  use Books.RepoCase

  @desc """
  Неописуем ужас дебне експедицията, предвождана от сър Джон Франклин из ледените пустини на Арктика.
  Според историческите данни през 1845 г. той и подчинените му смелчаци се отправят из смразяващите простори на Полярния кръг в търсене на легендарния Северозападен проход — морски път, съединяващ Атлантическия и Тихия океан… Ала нито един от 128-те души не се завръща.
  Странното им изчезване остава загадка и до днес, но сега мистерията е разплетена от въображението на Дан Симънс — чудовищният му талант, доказан с мащабни творби като Хиперион, Олимп и Лешояди, изплита неустоима комбинация от исторически факти и жанрова фантазия сред безкрайните ледове на една от най-негостоприемните за човека територии на планетата.
  """

  test "schemaless queries" do
    insert_test_books!()

    books = Books.books_by_year(2013)
    assert books == []

    book_id =
      Books.insert_book!("978-619-152-344-3", "Ужас", @desc, "Дан Симънс", 2013, "български")

    assert is_integer(book_id) && book_id > 0

    books = Books.books_by_year(2013)
    refute books == []
    assert Enum.count(books) == 1

    [book] = books
    assert %{author_name: "Дан Симънс", title: "Ужас"} == book

    book = Books.book_by_id(book_id)
    assert %{author_name: "Дан Симънс", title: "Ужас", id: book_id, year: 2013} == book

    books = Books.books_by_years_or_authors([2013], [])
    [book] = books

    assert %{
             author_name: "Дан Симънс",
             title: "Ужас",
             id: book_id,
             isbn: "978-619-152-344-3",
             year: 2013,
             description: @desc
           } == book

    Books.update_book_description!(book_id, "НЯМА")

    books = Books.books_by_years_or_authors([2013], [])
    [book] = books

    assert %{
             author_name: "Дан Симънс",
             title: "Ужас",
             id: book_id,
             isbn: "978-619-152-344-3",
             year: 2013,
             description: "НЯМА"
           } == book

    Books.delete_book_by_isbn!("978-619-152-344-3")

    books = Books.books_by_year(2013)
    assert books == []
  end
end
