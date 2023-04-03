defmodule ECIO.Server do
  @moduledoc false

  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init([init_args]) do
    # port = Port.open({:spawn, "tty_sl -c -e"}, [:binary, :eof])
    # send(port, [5|:unicode.characters_to_binary('hey',:utf8)])

    {:ok, init_args}
  end

  #  @impl GenServer
  #  def handle_info({:io_request, from, ref, {:put_chars, :unicode, msg}}, state) do
  #    IO.write(IO.ANSI.format([:yellow, msg]))
  #    send(from, {:io_reply, ref, :ok})
  #
  #    {:noreply, state}
  #  end

  @impl GenServer
  def handle_info({:io_request, from, ref, request}, state) do
    case check_request(request, state) do
      {tag, reply, new_state} when tag in [:ok, :error] ->
        send_reply(from, ref, reply)

        {:noreply, new_state}

        {:stop, reply, new_state}
        send_reply(from, ref, reply)

        {:stop, :normal, new_state}
    end
  end

  defp send_reply(from, ref, reply) do
    send(from, {:io_reply, ref, reply})
  end

  defp check_request({:put_chars, encoding, chars}, state) do
    put_chars(:unicode.characters_to_list(chars, encoding), state)
  end

  defp check_request({:put_chars, encoding, m, f, a}, state) do
    try do
      check_request({:put_chars, encoding, apply(m, f, a)}, state)
    catch
      _ ->
        {:error, {:error, f}, state}
    end
  end

  defp put_chars(chars, %{ansi_format: ansi_format} = state) do
    IO.write(IO.ANSI.format(ansi_format ++ [chars]))

    {:ok, :ok, state}
  end
end
