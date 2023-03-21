defmodule Pool.Manager do
  use GenServer

  require Logger

  @type t :: %__MODULE__{
          size: pos_integer(),
          workers: [pid()],
          user_monitors: %{reference() => pid()}
        }

  defstruct [:size, workers: [], user_monitors: %{}]

  #######
  # API #
  #######

  def child_spec(size) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [size]}
    }
  end

  def start_link(size) when is_integer(size) and size > 0 do
    GenServer.start_link(__MODULE__, size, name: __MODULE__)
  end

  def checkout() do
    GenServer.call(__MODULE__, :checkout)
  end

  def checkin(worker) do
    GenServer.cast(__MODULE__, {:checkin, worker})
  end

  #############
  # Callbacks #
  #############

  @impl GenServer
  def init(size) do
    Process.flag(:trap_exit, true)

    {:ok, %__MODULE__{size: size}, {:continue, :setup_workers}}
  end

  @impl GenServer
  def handle_continue(:setup_workers, %__MODULE__{size: size} = state) do
    workers = Enum.map(1..size, &start_worker/1)

    {:noreply, %__MODULE__{state | workers: workers}}
  end

  @impl GenServer
  def handle_call(:checkout, _from, %__MODULE__{workers: []} = state) do
    {:reply, :no_workers_available, state}
  end

  @impl GenServer
  def handle_call(
        :checkout,
        {from, _},
        %__MODULE__{workers: [worker | rest], user_monitors: monitors} = state
      ) do
    ref = Process.monitor(from)
    monitors = monitors |> Map.put(ref, worker)
    Process.put(worker, ref)

    {:reply, worker, %{state | workers: rest, user_monitors: monitors}}
  end

  @impl GenServer
  def handle_cast(
        {:checkin, worker},
        %__MODULE__{workers: workers, user_monitors: monitors} = state
      ) do
    monitors =
      case Process.delete(worker) do
        ref when is_reference(ref) ->
          Map.delete(monitors, ref)

        nil ->
          monitors
      end

    {:noreply, %{state | workers: [worker | workers], user_monitors: monitors}}
  end

  @impl GenServer
  def handle_info(
        {:DOWN, ref, :process, _, _},
        %__MODULE__{workers: workers, user_monitors: monitors} = state
      ) do
    workers =
      case Map.get(monitors, ref) do
        nil ->
          workers

        worker ->
          Logger.info("Checking in unused worker #{inspect(worker)}")

          Process.delete(worker)
          [worker | workers]
      end

    monitors = Map.delete(monitors, ref)

    {:noreply, %{state | workers: workers, user_monitors: monitors}}
  end

  @impl GenServer
  def handle_info(
        {:EXIT, pid, _reason},
        %__MODULE__{workers: workers, user_monitors: monitors} = state
      ) do
    Logger.warning("Worker #{inspect(pid)} has died")

    new_state =
      case Process.delete(pid) do
        ref when is_reference(ref) ->
          true = Process.demonitor(ref)
          monitors = Map.delete(monitors, ref)
          workers = workers |> Enum.reject(&(&1 == pid))
          workers = [Pool.WorkerSupervisor.start_worker(Pool.Worker) | workers]

          %__MODULE__{state | workers: workers, user_monitors: monitors}

        nil ->
          workers = workers |> Enum.reject(&(&1 == pid))
          workers = [Pool.WorkerSupervisor.start_worker(Pool.Worker) | workers]

          %__MODULE__{state | workers: workers}
      end

    {:noreply, new_state}
  end

  ###########
  # Private #
  ###########

  defp start_worker(_) do
    Pool.WorkerSupervisor.start_worker(Pool.Worker)
  end
end
