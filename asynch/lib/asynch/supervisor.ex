defmodule Asynch.Supervisor do
  use DynamicSupervisor

  @doc false
  def child_spec(config) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, config}
    }
  end

  @doc false
  def start_link(config),
    do: DynamicSupervisor.start_link(__MODULE__, config, name: __MODULE__)

  @doc false
  def start_child(topic, name) do
    spec = {Asynch.Listener.Supervisor, topic: topic, name: name}

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(config),
    do: DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [config])
end
