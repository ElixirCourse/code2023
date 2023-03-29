defmodule Pool.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, args) do
    size = Keyword.get(args, :default_size, 10)

    children = [
      Pool.WorkerSupervisor,
      {Pool.Manager, size}
    ]

    opts = [strategy: :one_for_all, name: Pool.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
