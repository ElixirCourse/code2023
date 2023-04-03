defmodule ECIO do
  @moduledoc """
  Documentation for `Ecio`.
  """

  def puts(data) do
    IO.puts(ECIO.Server, data)
  end

  def put_chars(data) do
    ref = make_ref()
    send(Process.group_leader(), {:io_request, self(), ref, {:put_chars, :unicode, data <> "\n"}})

    receive do
      {:io_reply, ^ref, :ok} ->
        :ok

      {:io_reply, ^ref, {:error, error}} ->
        raise error
    end
  end
end
