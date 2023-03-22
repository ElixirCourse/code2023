defmodule Asynch.Processor do
  @moduledoc """
  Processor for asynchronous actions that can notify after they are ready.
  """

  use GenServer

  require Logger

  #######
  # API #
  #######

  def process(mod, fun, args) do
    operation_id = UUID.uuid4()

    GenServer.cast(__MODULE__, {:process, {operation_id, mod, fun, args}})

    operation_id
  end

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  #############
  # Callbacks #
  #############

  def init([]) do
    {:ok, %{}}
  end

  def handle_cast({:process, {operation_id, mod, fun, args}}, state) do
    task = Task.Supervisor.async_nolink(:tasks_supervisor, mod, fun, args)
    ref = task.ref

    {:noreply, Map.merge(state, %{operation_id => {task, {mod, fun, args}}, ref => operation_id})}
  end

  def handle_info({ref, result}, state) when is_reference(ref) do
    operation_id = Map.get(state, ref)
    Logger.info("Result for operation #{operation_id} : #{inspect(result)}")

    # Cleanup
    state = Map.drop(state, [operation_id, ref])

    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, _, :normal}, state) do
    {:noreply, state}
  end
end
