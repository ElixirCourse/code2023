defmodule Asynch.Listener do
  @type options :: map()

  @callback initialize(options()) :: options()

  @callback on_error(operation_id :: UUID.t(), error :: term(), options()) :: :ok
  @callback on_success(operation_id :: UUID.t(), result :: term(), options()) :: :ok

  @optional_callbacks initialize: 1,
                      on_error: 3,
                      on_success: 3

  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour Asynch.Listener

      @doc false
      def initialize(options), do: options

      @doc false
      def on_error(_, _, _), do: :ok

      @doc false
      def on_success(_, _, _), do: :ok

      defoverridable initialize: 1, on_error: 3, on_success: 3
    end
  end

  def implements?(module) when is_atom(module) do
    with {:module, ^module} <- Code.ensure_compiled(module),
         true <- function_exported?(module, :__info__, 1),
         true <- function_exported?(module, :initialize, 1),
         true <- function_exported?(module, :on_error, 3),
         true <- function_exported?(module, :on_success, 3) do
      true
    else
      _ ->
        false
    end
  end

  def implements?(_module), do: false
end
