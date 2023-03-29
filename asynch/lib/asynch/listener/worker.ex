defmodule Asynch.Listener.Worker do
  use GenServer

  @main_topic "main"

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args]},
      restart: :transient,
      type: :worker
    }
  end

  def start_link(%{module: _, options: _} = listener) do
    GenServer.start_link(__MODULE__, listener)
  end

  @impl true
  def init(%{options: options, module: listener} = state) do
    Registry.register(Asynch.PubSub, @main_topic, [])

    initialized_state = %{state | options: listener.initialize(options)}

    {:ok, initialized_state}
  end

  @impl true
  def handle_cast({:update, operation_id, result}, state) do
    {:noreply, handle_result(operation_id, result, state)}
  end

  def handle_cast({:unregister, _topic}, state) do
    :ok = Registry.unregister(Asynch.PubSub, @main_topic)

    if Registry.keys(Asynch.PubSub, self()) == [] do
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  defp handle_result(
         operation_id,
         result,
         %{module: listener, options: options} = state
       ) do
    case result do
      :ok ->
        listener.on_success(operation_id, :ok, options)
        state

      {:ok, data} ->
        listener.on_success(operation_id, data, options)
        state

      {:error, reason} ->
        listener.on_error(operation_id, reason, options)
        state

      {:ok, data, updated_options} ->
        listener.on_success(operation_id, data, updated_options)
        %{state | options: updated_options}

      {:error, reason, updated_options} ->
        listener.on_error(operation_id, reason, updated_options)
        %{state | options: updated_options}
    end
  end
end
