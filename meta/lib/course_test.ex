defmodule CourseTest do
  defmacro __using__(_) do
    quote do
      import(unquote(__MODULE__))
      Module.register_attribute(__MODULE__, :tests, accumulate: true)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def run(), do: CourseAssertion.Test.run(__MODULE__, @tests)
    end
  end

  defmacro test(description, do: code_block) do
    name = String.to_atom(description)

    quote do
      @tests {unquote(name), unquote(description)}
      def unquote(name)(), do: unquote(code_block)
    end
  end

  defmacro assert({operation, _, args}) do
    quote do
      CourseAssertion.Test.assert(unquote(operation), unquote(args), __ENV__)
    end
  end
end

defmodule CourseAssertion.Test do
  def run(module, tests) do
    Enum.map(tests, fn
      {func, _description} ->
        apply(module, func, [])
    end)
  end

  def assert(:<, [lhs, rhs], _) when lhs < rhs do
    IO.puts "."
    :ok
  end

  def assert(:<, [lhs, rhs], env) do
    {:current_stacktrace, [_ | stacktrace]} = Process.info(self(), :current_stacktrace)

    IO.puts("""
    ========================================================================
    Expected the left side to be less than the rigth side:
    Code: #{Macro.to_string({:<, [], [lhs, rhs]})}
       Left: #{inspect(lhs)}
      Right: #{inspect(rhs)}
    #{env.file()}:#{env.line()}
    Stacktrace:
    #{Exception.format_stacktrace(stacktrace)}
    ========================================================================
    """)

    :error
  end

  def assert(:==, [value, value], _) do
    IO.puts "."
    :ok
  end

  def assert(:==, [lhs, rhs], env) do
    {:current_stacktrace, [_ | stacktrace]} = Process.info(self(), :current_stacktrace)

    IO.puts("""
    ========================================================================
    Expected the left side to be equal to the rigth side:
    Code: #{Macro.to_string({:==, [], [lhs, rhs]})}
       Left: #{inspect(lhs)}
      Right: #{inspect(rhs)}
    #{env.file()}:#{env.line()}
    Stacktrace:
    #{Exception.format_stacktrace(stacktrace)}
    ========================================================================
    """)

    :error
  end
end

defmodule TestCaller do
  use CourseTest

  test "super cool test" do
    assert 1 == 2
  end

  test "super cool test2", do: assert(1 == 1)

  test "super cool test3", do: assert(1 == 3)

  test "we can assert on operators" do
    assert 5 < 4
  end
end

TestCaller.run()
