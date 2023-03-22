defmodule FileBuffer.Plain do
  @flush_period 15_000
  @buffer_size 100

  # Стартира нов процес, който се грижи за записването на данните във файл
  # Регистрира процеса под името name
  def start_link(name \\ nil) do
    pid =
      spawn_link(fn ->
        if name, do: :erlang.register(name, self())
        timer = Process.send_after(self(), :flush, @flush_period)

        loop(%{
          buffer: [],
          file: "filebuffer.txt",
          timer: timer,
          started_at: DateTime.utc_now(),
          insert_counter: 0
        })
      end)

    {:ok, pid}
  end

  # Добавя данни в буфера без да чака тези данни да бъдат добавени
  def insert_nowait(pid, data) do
    send(pid, {:insert_nowait, data})
    :ok
  end

  # Добавя данни в буфера и чака потвърждение за това
  def insert_wait(pid, data, timeout \\ 5000) do
    sender_alias = Process.monitor(pid, alias: :demonitor)
    send(pid, {:insert_wait, sender_alias, data})

    receive do
      {^sender_alias, :ok} ->
        :ok

      {:DOWN, ^sender_alias, _, _, _} ->
        {:error, :process_died}
    after
      timeout -> {:error, :timeout}
    end
  end

  # Записва всички данни от буфера във файл
  def flush(pid, timeout \\ 5000) do
    sender_alias = Process.monitor(pid, alias: :demonitor)
    send(pid, {:flush, sender_alias})

    receive do
      {^sender_alias, :ok} ->
        Process.demonitor(sender_alias, [:flush])
        :ok

      {:DOWN, ^sender_alias, _, _, _} ->
        {:error, :process_died}
    after
      timeout -> 
        Process.demonitor(sender_alias, [:flush])
        {:error, :timeout}
    end
  end

  # Връща данни за буфера
  def info(pid, timeout \\ 5000) do
    sender_alias = Process.monitor(pid, alias: :demonitor)
    send(pid, {:info, sender_alias})

    receive do
      {^sender_alias, info} ->
        Process.demonitor(sender_alias, [:flush])
        {:ok, info}

      {:DOWN, ^sender_alias, _, _, _} ->
        {:error, :process_died}
    after
      timeout ->
        Process.demonitor(sender_alias, [:flush])
        {:error, :timeout}
    end
  end

  # work-loop на процеса. Обработва получените съобщения
  defp loop(state) do
    receive do
      {:insert_nowait, data} ->
        buffer = List.wrap(data) ++ state.buffer
        state = do_insert(buffer, state)

        loop(state)

      {:insert_wait, sender_alias, data} ->
        buffer = List.wrap(data) ++ state.buffer
        state = do_insert(buffer, state)
        send(sender_alias, {sender_alias, :ok})

        loop(state)

      {:flush, sender_alias} ->
        :ok = do_flush(state.buffer, state.file)
        send(sender_alias, {sender_alias, :ok})
        timer = Process.send_after(:self, :flush, @flush_period)

        state
        |> Map.put(:buffer, [])
        |> Map.put(:timer, timer)
        |> loop()

      :flush ->
        :ok = do_flush(state.buffer, state.file)
        timer = Process.send_after(:self, :flush, @flush_period)

        state
        |> Map.put(:buffer, [])
        |> Map.put(:timer, timer)
        |> loop()

      {:info, sender_alias} ->
        buffer_length = length(state.buffer)

        info = %{
          buffer_length: buffer_length,
          items_before_flush: @buffer_size - buffer_length,
          time_before_flush: :erlang.read_timer(state.timer),
          started_at: state.started_at
        }

        send(sender_alias, {sender_alias, info})
        loop(state)

      :stop ->
        :ok = do_flush(state.buffer, state.file)
    end
  end

  defp do_insert(buffer, state) do
    if length(buffer) >= @buffer_size do
      Process.cancel_timer(state.timer)
      timer = Process.send_after(:self, :flush, @flush_period)
      :ok = do_flush(buffer, state.file)

      state
      |> Map.put(:buffer, [])
      |> Map.put(:timer, timer)
      |> Map.update!(:insert_counter, &(&1 + 1))
    else
      Map.put(state, :buffer, buffer)
    end
  end

  defp do_flush(buffer, file) do
    buffer =
      buffer
      |> Enum.reverse()
      |> Enum.join("\n")

    Process.sleep(100)
    File.write(file, buffer, [:append, :write])
  end
end

# {:ok, pid} = FileBuffer.Plain.start_link()

# dt = DateTime.utc_now()
# IO.puts("Start writing...")

# for _ <- 1..20 do
#   FileBuffer.Plain.insert_wait(pid, "hello")
#   FileBuffer.Plain.insert_wait(pid, "goodbye")
# end

# IO.inspect(FileBuffer.Plain.info(pid))
