defmodule ECIO.SocketListener do
  def child_spec(opts) do
    :ranch.child_spec(__MODULE__, :ranch_tcp, opts, ECIO.SocketPrinter, [])
  end
end
