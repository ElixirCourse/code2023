defmodule Asynch.MixProject do
  use Mix.Project

  def project do
    [
      app: :asynch,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

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

  defp aliases do
    [
      # test: "test --no-start"
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
