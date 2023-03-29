defmodule Asynch.ProcessorTest do
  use ExUnit.Case

  test "works" do
    task_id = Asynch.Processor.process(Asynch.Tasks, :sum, [[1, 2, 3, 4, 5]])
    IO.inspect(task_id)

    {:ok, subscription} = Asynch.Processor.subscribe(Asynch.Listener.ResultLog)

    task_id = Asynch.Processor.process(Asynch.Tasks, :sum, [1..200 |> Enum.to_list()])
    IO.inspect(task_id)

    # :sys.get_state(Asynch.Processor)
    Process.sleep(1000)
  end
end
