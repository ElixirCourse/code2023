defmodule Asynch.Listener.Supervisor do
  use DynamicSupervisor

  alias Asynch.Listener.Worker

  @doc false
  def start_link(config, topic: topic, name: name) do
    config = Keyword.put(config, :topic, topic)
    DynamicSupervisor.start_link(__MODULE__, config, name: name)
  end

  @doc false
  def start_child(sup, listener, options) do
    spec = Worker.child_spec(%{module: listener, options: options})

    DynamicSupervisor.start_child(sup, spec)
  end

  @impl true
  def init(_), do: DynamicSupervisor.init(strategy: :one_for_one)
end
