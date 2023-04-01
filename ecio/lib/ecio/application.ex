defmodule ECIO.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :duplicate, name: ECIO.PubSub, partitions: System.schedulers_online()},
      {ECIO.Server, [%{ansi_format: [:red]}]},
      {ECIO.Device, [[]]},
      {ECIO.SocketListener, [{:port, 5556}]}
    ]

    opts = [strategy: :one_for_one, name: ECIO.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
