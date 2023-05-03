defmodule Books.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Books.Repo

      import Ecto
      import Ecto.Query
      import Books.RepoCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Books.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Books.Repo, {:shared, self()})
    end

    :ok
  end

  def insert_test_books! do
    query = """
    INSERT INTO countries (name, code, inserted_at, updated_at)
      VALUES ($1, $2, now(), now()) RETURNING id
    """

    {:ok, %{rows: [[country_id]]}} = Books.Repo.query(query, ["USA", "US"])

    query = """
    INSERT INTO authors (first_name, last_name, birth_date, country_id, inserted_at, updated_at)
      VALUES ($1, $2, $3, $4, now(), now()) RETURNING id
    """

    {:ok, %{rows: [[author_id]]}} =
      Books.Repo.query(query, ["Стивън", "Кинг", Date.from_iso8601!("1947-09-21"), country_id])

    query = """
    INSERT INTO books (isbn, title, description, year, language, inserted_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, now(), now()) RETURNING id
    """

    description = """
    Чикаго.
    Само дето от време на време по шосето минават огромни камиони, които нарушават тишината със заплашителен
    грохот.
    Зад къщата се вие грижливо разчистена от децата пътека, която води към малкото гробище за домашни любимци.
    Над него, на върха на далечния хълм се намира друго гробище — на древното индианско племе „Микмак“.
    Местните жители вярват, че погребаните там могат да възкръсват…
    """

    {:ok, %{rows: [[book_id]]}} =
      Books.Repo.query(query, [
        "954-409-083-5",
        "Гробище за домашни любимци",
        description,
        1993,
        "български"
      ])

    query = """
    INSERT INTO authors_books (author_id, book_id) VALUES ($1, $2)
    """

    {:ok, _} = Books.Repo.query(query, [author_id, book_id])

    query = """
    INSERT INTO authors (first_name, last_name, birth_date, country_id, inserted_at, updated_at)
      VALUES ($1, $2, $3, $4, now(), now()) RETURNING id
    """

    {:ok, %{rows: [[author_id]]}} =
      Books.Repo.query(query, ["Майкъл", "Крайтън", Date.from_iso8601!("1942-10-23"), country_id])

    description = """
    След „Юрски парк“ Майкъл Крайтън поднася поредния си бестселър „Изгряващо слънце“, чиято екранизация, подобно на „Джурасик парк“, стана събитие във филмовия свят.
    На пищен прием в нюйоркски небостъргач, собственост на японската фирма Накамото, е извършено убийство. Насред заседателната зала един любовен акт завършва с фатален край. Сексуално мотивирано деяние или… може би с политически привкус? В динамичното полицейско разследване писателят — виртуоз на трилъра, вплита два типа ценностни системи, два културни модела — на държавите, оспорващи си първенството на планетата. Едно слънце изгрява над Америка, японското, мъчейки се да засенчи нейната икономическа мощ, доминирането и присъствие в света. Кому принадлежи бъдещето — на напористата, експанзивна Америка или на незабележимо, но упорито преследващата амбициозните си цели Япония?
    А вероятно българският читател ще си зададе още куп въпроси, свързани със съдбата на собствената му страна, породени от недвусмисленото послание на автора — просперитетът и престижът са несъвместими със зависимостта от нечие влияние, от нечий финансов и психологически натиск.
    """

    query = """
    INSERT INTO books (isbn, title, description, year, language, inserted_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, now(), now()) RETURNING id
    """

    {:ok, %{rows: [[book_id]]}} =
      Books.Repo.query(query, [
        "954-428-058-8",
        "Изгряващо слънце",
        description,
        1993,
        "български"
      ])

    query = """
    INSERT INTO authors_books (author_id, book_id) VALUES ($1, $2)
    """

    {:ok, _} = Books.Repo.query(query, [author_id, book_id])
  end
end
