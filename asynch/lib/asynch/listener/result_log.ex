defmodule Asynch.Listener.ResultLog do
  use Asynch.Listener

  require Logger

  def on_success(operation_id, result, _) do
    Logger.info("Result for operation #{operation_id} : #{inspect(result)}")

    :ok
  end
end
