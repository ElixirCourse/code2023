defmodule ECIO.Context do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    :ets.new(__MODULE__, [:public, :named_table, :ordered_set])

    {:ok, []}
  end
end
