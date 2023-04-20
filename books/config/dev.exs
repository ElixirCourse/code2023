import Config

config :books, Books.Repo,
  database: "books_dev",
  username: "booker",
  password: "bookerpass",
  hostname: "localhost"
