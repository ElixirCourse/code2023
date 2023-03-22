defmodule Asynch.Processor do
  @moduledoc """
  Processor for asynchronous actions that can notify after they are ready.
  """

  use GenServer

  alias Asynch.Listener

  require Logger

  defstruct operations: %{}

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

  def unsubscribe(subscription) when is_reference(subscription) or is_pid(subscription) do
    GenServer.call(__MODULE__, {:unsubscribe, subscription})
  end

  def start_or_get_topic_supervisor(topic) when is_binary(topic) do
    {Asynch.Registry, {Asynch.Listener.Supervisor, topic}}
    |> Registry.whereis_name()
    |> case do
      :undefined ->
        name = {:via, Registry, {Asynch.Registry, {Asynch.Listener.Supervisor, topic}}}

        Asynch.Supervisor.start_child(topic, name)

      pid when is_pid(pid) ->
        {:ok, pid}
    end
  end

  def start_listener(topic, listener) when is_binary(topic) do
    {:ok, pid} = start_or_get_topic_supervisor(topic)

    {:ok, _} = Asynch.Listener.Supervisor.start_child(pid, listener, [])
  end

  #############
  # Callbacks #
  #############

  def init([]) do
    {:ok, %__MODULE__{}}
  end

  def handle_call({:subscribe, listener}, _from, %__MODULE__{} = state) do
    {:ok, subscription} = start_listener("main", listener)

    {:reply, subscription, state}
  end

  def handle_call({:unsubscribe, subscription}, _from, %__MODULE__{} = state) do
    GenServer.cast(subscription, {:unregister, "main"})

    {:reply, true, state}
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
        %__MODULE__{operations: operations} = state
      )
      when is_reference(ref) do
    operation_id = Map.get(operations, ref)

    Registry.dispatch(
      Asynch.PubSub,
      "main",
      fn sups ->
        Enum.each(sups, fn {pid, _} ->
          GenServer.cast(pid, {:update, operation_id, result})
        end)
      end
    )

    # Cleanup
    operations = Map.drop(operations, [operation_id, ref])

    {:noreply, %__MODULE__{state | operations: operations}}
  end

  def handle_info({:DOWN, _, :process, _, :normal}, state) do
    {:noreply, state}
  end

  ###########
  # Private #
  ###########
end
