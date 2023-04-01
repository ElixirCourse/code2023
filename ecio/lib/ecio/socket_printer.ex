defmodule ECIO.SocketPrinter do
  @moduledoc false

  use GenServer

  @behaviour :ranch_protocol

  @topic :socket_printer

  @impl true
  def start_link(ref, transport, opts) do
    GenServer.start_link(__MODULE__, {ref, transport, opts})
  end

  def topic, do: @topic

  @impl true
  def init({ref, transport, _opts}) do
    {:ok, {ref, transport}, {:continue, :init_socket}}
  end

  @impl true
  def handle_continue(:init_socket, {ref, transport} = state) do
    Registry.register(ECIO.PubSub, @topic, [])

    {:ok, socket} = :ranch.handshake(ref)
    :ok = transport.setopts(socket, [{:active, true}])

    {:noreply, {socket, transport}}
  end

  @impl true
  def handle_info({:tcp, socket, data}, {socket, transport} = state) do
    GenServer.cast(ECIO.Device, {:store_input, data})
    :ok = transport.send(socket, data)

    {:noreply, state}
  end

  @impl true
  def handle_info(_, {socket, transport} = state) do
    :ok = Registry.unregister(ECIO.PubSub, @topic)
    transport.close(socket)

    {:stop, :shutdown, state}
  end

  @impl true
  def handle_cast({:send, data}, {socket, transport} = state) do
    :ok = transport.send(socket, data)

    {:noreply, state}
  end
end
