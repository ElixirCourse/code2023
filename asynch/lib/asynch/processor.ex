defmodule Asynch.Processor do
  @moduledoc """
  Processor for asynchronous actions that can notify after they are ready.
  """

  use GenServer

  alias Asynch.Listener

  require Logger

  defstruct operations: %{}, listeners: %{}

  #######
  # API #
  #######

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def process(mod, fun, args) do
    operation_id = UUID.uuid4()

    GenServer.cast(__MODULE__, {:process, {operation_id, mod, fun, args}})

    operation_id
  end

  def subscribe(listener) do
    if Listener.implements?(listener) do
      {:ok, GenServer.call(__MODULE__, {:subscribe, listener})}
    else
      {:error, :invalid_listener}
    end
  end

  def unsubscribe(subscription) when is_reference(subscription) do
    GenServer.call(__MODULE__, {:unsubscribe, subscription})
  end

  #############
  # Callbacks #
  #############

  def init([]) do
    {:ok, %__MODULE__{}}
  end

  def handle_call({:subscribe, listener}, _from, %__MODULE__{listeners: listeners} = state) do
    subscription = make_ref()
    listeners = Map.put(listeners, subscription, listener)

    {:reply, subscription, %__MODULE__{state | listeners: listeners}}
  end

  def handle_call({:unsubscribe, subscription}, _from, %__MODULE__{listeners: listeners} = state) do
    if Map.has_key?(listeners, subscription) do
      listeners = Map.delete(listeners, subscription)

      {:reply, true, %__MODULE__{state | listeners: listeners}}
    else
      {:reply, false, state}
    end
  end

  def handle_cast(
        {:process, {operation_id, mod, fun, args}},
        %__MODULE__{operations: operations} = state
      ) do
    task = Task.Supervisor.async_nolink(:tasks_supervisor, mod, fun, args)
    ref = task.ref

    operations =
      Map.merge(operations, %{operation_id => {task, {mod, fun, args}}, ref => operation_id})

    {:noreply, %__MODULE__{state | operations: operations}}
  end

  def handle_info(
        {ref, result},
        %__MODULE__{operations: operations, listeners: listeners} = state
      )
      when is_reference(ref) do
    operation_id = Map.get(operations, ref)

    listeners
    |> Map.values()
    |> Enum.each(fn listener ->
      listener.on_success(operation_id, result, :not_implemented)
    end)

    # Cleanup
    operations = Map.drop(operations, [operation_id, ref])

    {:noreply, %__MODULE__{state | operations: operations}}
  end

  def handle_info({:DOWN, _, :process, _, :normal}, state) do
    {:noreply, state}
  end
end
