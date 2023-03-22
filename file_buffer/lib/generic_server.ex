# defmodule GenericServer do
#   @spec start_link(Module.t(), Keyword.t()) :: {:ok, pid}
#   def start_link(module, opts \\ []) do
#   end

#   @spec call(pid, any, timeout) :: any
#   def call(pid, msg, timeout \\ 5000) do
#   end

#   @spec call(pid, any) :: :ok
#   def cast(pid, msg) do
#   end

#   @spec call(Module.t(), any) :: no_return() | :ok
#   defp loop(module, state) do
#   end

#   @spec call({pid | reference, reference}, any) :: :ok
#   defp reply({pid_or_alias, ref}, msg) do
#   end
# end
