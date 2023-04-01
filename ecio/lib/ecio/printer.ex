defmodule ECIO.Printer do
  @moduledoc false

  use GenServer

  def start_link(device, message, name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, {device, message}, name: name)
  end

  @impl GenServer
  def init({device, message}) do
    Process.send_after(self(), :print, 10_000)

    {:ok, %{device: device, message: message}}
  end

  @impl GenServer
  def handle_info(:print, %{device: device, message: message} = state) do
    IO.puts(device, message)
    Process.send_after(self(), :print, 10_000)

    {:noreply, state}
  end
end
