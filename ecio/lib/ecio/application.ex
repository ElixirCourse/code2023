defmodule ECIO.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {ECIO.Server, [%{ansi_format: [:red]}]}
    ]

    opts = [strategy: :one_for_one, name: ECIO.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
