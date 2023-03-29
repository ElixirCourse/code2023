defmodule Pool.Worker do
  use GenServer

  require Logger

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      restart: :temporary,
      type: :worker
    }
  end

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def execute(worker, fun) do
    GenServer.call(worker, {:execute, fun})
  end

  def init(_) do
    Logger.info("Worker #{inspect(self())} is being started")

    {:ok, %{}}
  end

  def handle_call({:execute, fun}, _from, state) when is_function(fun, 0) do
    result = fun.()

    {:reply, result, state}
  end
end
