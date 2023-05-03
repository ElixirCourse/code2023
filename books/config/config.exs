import Config

config :books,
  ecto_repos: [Books.Repo]

config :books, Books.Repo,
  database: "books",
  username: "booker",
  password: "bookerpass",
  hostname: "localhost"

import_config "#{config_env()}.exs"
