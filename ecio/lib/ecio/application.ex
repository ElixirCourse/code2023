defmodule ECIO.Application do
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(type, args) do
    Logger.info("ECIO Application started with type #{inspect(type)} and args #{inspect(args)}")
    port = System.get_env("PORT", "5555") |> String.to_integer()

    children = [
      {Registry, keys: :duplicate, name: ECIO.PubSub, partitions: System.schedulers_online()},
      ECIO.Context,
      {ECIO.Server, [%{ansi_format: [:red]}]},
      {ECIO.Device, [[]]},
      {ECIO.SocketListener, [{:port, port}]}
    ]

    opts = [strategy: :one_for_one, name: ECIO.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
