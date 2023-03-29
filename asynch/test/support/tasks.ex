defmodule Asynch.Tasks do
  def sum(l) when is_list(l) do
    {:ok, Enum.sum(l)}
  end
end
