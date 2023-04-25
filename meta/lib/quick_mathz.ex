defmodule QuickMathz do
  @values [{:one, 1}, {:two, :two}, {:three, 3}]

  Enum.each(@values, fn {name, value} ->
    def unquote(name)(), do: unquote(value)
  end)
end

QuickMathz.three()
|> IO.inspect()
