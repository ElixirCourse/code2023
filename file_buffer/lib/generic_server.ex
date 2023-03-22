defmodule GenericServer do
  def start_link(module, init_arg, opts \\ []) do
    ref = make_ref()
    parent = self()

    pid =
      spawn_link(fn ->
        if name = Keyword.get(opts, :name) do
          Process.register(self(), name)
        end

        {:ok, state} = module.init(init_arg)
        send(parent, {ref, :ok})

        loop(module, state)
      end)

    receive do
      {^ref, :ok} -> {:ok, pid}
    after
      5000 -> {:error, :timeout}
    end
  end

  def call(pid, msg, timeout \\ 5000) do
    ref = Process.monitor(pid, alias: :demonitor)
    send(pid, {:call, msg, {ref, ref}})

    receive do
      {^ref, response} ->
        Process.demonitor(ref, [:flush])
        response

      {:DOWN, ^ref, _, _, reason} ->
        exit(reason)
    after
      timeout ->
        Process.demonitor(ref, [:flush])
        exit(:timeout)
    end
  end

  def cast(pid, msg) do
    send(pid, {:cast, msg})
    :ok
  end

  def loop(module, state) do
    receive do
      {:call, msg, from} ->
        {:reply, response, new_state} = module.handle_call(msg, from, state)
        reply(from, response)
        loop(module, new_state)

      {:cast, msg} ->
        {:noreply, new_state} = module.handle_cast(msg, state)
        loop(module, new_state)

      :terminate ->
        module.terminate(state)
        :ok

      msg ->
        {:noreply, new_state} = module.handle_info(msg, state)
        loop(module, new_state)
    end
  end

  defp reply({pid, ref} = _from, msg) do
    send(pid, {ref, msg})
  end
end
