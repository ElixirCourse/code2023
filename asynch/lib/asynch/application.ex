defmodule Asynch.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: :tasks_supervisor},
      Asynch.Processor
    ]

    opts = [strategy: :one_for_one, name: Asynch.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
