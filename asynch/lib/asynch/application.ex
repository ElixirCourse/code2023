defmodule Asynch.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Asynch.Registry},
      {Registry, keys: :duplicate, name: Asynch.PubSub, partitions: System.schedulers_online()},
      {Task.Supervisor, name: :tasks_supervisor},
      Asynch.Processor,
      {Asynch.Supervisor, [[]]}
    ]

    opts = [strategy: :one_for_one, name: Asynch.Root.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
