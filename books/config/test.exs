import Config

config :books, Books.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "books_test",
  username: "booker",
  password: "bookerpass",
  hostname: "localhost"
