defmodule Asynch.MixProject do
  use Mix.Project

  def project do
    [
      app: :asynch,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Asynch.Application, []}
    ]
  end

  defp deps do
    [
       {:uuid, "~> 1.1"}
    ]
  end
end
