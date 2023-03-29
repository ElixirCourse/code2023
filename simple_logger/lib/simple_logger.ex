defmodule SimpleLogger do
  @levels [:info, :error, :warn, :trace, :debug]
  @root File.cwd!()

  # Demo with
  # Port.open({:spawn, "cat"}, [:binary])

  # What can be sent:
  # {Pid,{command,Data}}
  # {Pid,close}
  # {Pid,{connect,NewPid}}

  # What is received
  # {Port,{data,Data}}
  # {Port,closed}
  # {Port,connected}
  # {'EXIT',Port,Reason}

  @enforce_keys [:logger, :level]
  defstruct [:logger, level: :info]

  def new(level \\ :info) when level in @levels do
    cmd = "sh #{Path.join(~w(#{@root} bin logger.sh))}"
    logger = Port.open({:spawn, cmd}, [:binary])

    %__MODULE__{logger: logger, level: level}
  end

  def log(%__MODULE__{logger: logger, level: level} = impl, message) do
    prefix = level |> Atom.to_string() |> String.at(0) |> String.upcase()
    date_time = DateTime.utc_now() |> DateTime.to_iso8601()

    true = Port.command(logger, "#{prefix} #{date_time} | #{message}\n")

    impl
  end

  def info(%__MODULE__{level: :info} = impl, message), do: log(impl, message)
  def info(%__MODULE__{level: _} = impl, message) do
    log(%{impl | level: :info}, message)
  end

  def error(%__MODULE__{level: :error} = impl, message), do: log(impl, message)
  def error(%__MODULE__{level: _} = impl, message) do
    log(%{impl | level: :error}, message)
  end

  def warn(%__MODULE__{level: :warn} = impl, message), do: log(impl, message)
  def warn(%__MODULE__{level: _} = impl, message) do
    log(%{impl | level: :warn}, message)
  end

  def trace(%__MODULE__{level: :trace} = impl, message), do: log(impl, message)
  def trace(%__MODULE__{level: _} = impl, message) do
    log(%{impl | level: :trace}, message)
  end

  def debug(%__MODULE__{level: :debug} = impl, message), do: log(impl, message)
  def debug(%__MODULE__{level: _} = impl, message) do
    log(%{impl | level: :debug}, message)
  end

  def close(%__MODULE__{logger: logger}) do
    Port.close(logger)
  end
end
