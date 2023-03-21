defmodule Pool.WorkerSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_worker(spec) do
    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, spec)

    true = Process.link(pid)
    pid
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
