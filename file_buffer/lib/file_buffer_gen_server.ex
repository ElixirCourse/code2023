defmodule FileBuffer.GenServer do
  use GenServer

  @flush_period 15_000
  @buffer_size 100

  def start_link(name \\ nil) do
    GenServer.start_link(__MODULE__, name: name)
  end

  def init(_) do
    {:ok,
     %{
       buffer: [],
       timer: Process.send_after(self(), :flush, @flush_period),
       file: "filebuffer.txt"
     }}
  end

  def insert_wait(pid, data, timeout \\ 5000),
    do: GenServer.call(pid, {:insert, data}, timeout)

  def insert_nowait(pid, data),
    do: GenServer.cast(pid, {:insert, data})

  def insert_flush(pid, timeout \\ 5000),
    do: GenServer.call(pid, :flush, timeout)

  def handle_call({:insert, data}, _from, state) do
    {:reply, :ok, do_insert(data, state)}
  end

  def handle_call(:flush, _from, state) do
    {:reply, :ok, do_flush(state)}
  end

  def handle_info(:flush, state) do
    {:noreply, do_flush(state)}
  end

  def handle_cast({:insert, data}, state) do
    {:reply, :ok, do_insert(data, state)}
  end

  defp do_insert(data, state) do
    buffer = List.wrap(data) ++ state.buffer

    if length(buffer) >= @buffer_size do
      Process.cancel_timer(state.timer)
      timer = Process.send_after(:self, :flush, @flush_period)
      :ok = do_flush(%{buffer: buffer, file: state.file})
      Map.put(state, :buffer, []) |> Map.put(:timer, timer)
    else
      Map.put(state, :buffer, buffer)
    end
  end

  defp do_flush(%{buffer: buffer, file: file}) do
    buffer =
      buffer
      |> Enum.reverse()
      |> Enum.join("\n")

    Process.sleep(100)
    File.write(file, buffer, [:append, :write])
  end
end
