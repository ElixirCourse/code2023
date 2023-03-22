defmodule FileBuffer.GenericServer do
  @flush_period 15_000
  @buffer_size 100

  def start_link(name \\ nil) do
    GenericServer.start_link(__MODULE__, name: name)
  end

  def init(_) do
    {:ok,
     %{
       buffer: [],
       timer: Process.send_after(self(), :flush, @flush_period),
       file: "filebuffer.txt",
       started_at: DateTime.utc_now()
     }}
  end

  def insert_wait(pid, data, timeout \\ 5000),
    do: GenericServer.call(pid, {:insert, data}, timeout)

  def insert_nowait(pid, data),
    do: GenericServer.cast(pid, {:insert, data})

  def info(pid, timeout \\ 5000),
    do: GenericServer.call(pid, :info, timeout)

  def flush(pid, timeout \\ 5000),
    do: GenericServer.call(pid, :flush, timeout)

  # handle_X functions

  def handle_call({:insert, data}, _from, state) do
    {:reply, :ok, do_insert(data, state)}
  end

  def handle_call(:flush, _from, state) do
    {:reply, :ok, do_flush(state)}
  end

  def handle_call(:info, _from, state) do
    buffer_length = length(state.buffer)

    info = %{
      buffer_length: buffer_length,
      items_before_flush: @buffer_size - buffer_length,
      time_before_flush: :erlang.read_timer(state.timer),
      started_at: state.started_at
    }

    {:reply, info, state}
  end

  def handle_info(:flush, state) do
    {:noreply, do_flush(state)}
  end

  def handle_cast({:insert, data}, state) do
    {:noreply, do_insert(data, state)}
  end

  defp do_insert(data, state) do
    buffer = List.wrap(data) ++ state.buffer

    case length(buffer) >= @buffer_size do
      true -> do_flush(%{state | buffer: buffer})
      false -> Map.put(state, :buffer, buffer)
    end
  end

  defp do_flush(%{buffer: buffer, file: file} = state) do
    Process.cancel_timer(state.timer)
    timer = Process.send_after(self(), :flush, @flush_period)

    :ok = write_to_file(buffer, file)

    Map.put(state, :buffer, []) |> Map.put(:timer, timer)
  end

  defp write_to_file([], _file), do: :ok

  defp write_to_file(buffer, file) do
    buffer = Enum.intersperse(buffer, "\n")

    buffer = buffer |> Enum.reverse()

    # Иначе последното съобщения от предния flush и първото от
    # текущия ще са на един ред
    buffer = if buffer == [], do: buffer, else: [buffer, "\n"]

    Process.sleep(100)
    File.write(file, buffer, [:append, :write])
  end
end
