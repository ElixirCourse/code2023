defmodule Adder do
  @attribute 3

  @attribute 4

  defmacro define(number) do
    name = :"add_#{number}"

    quote do
      def unquote(name)(arg), do: unquote(number) + arg
    end
  end

  name = :foo

  def unquote(name)(), do: :bar

  def attr() do
    @attribute
  end
end


defmodule Test do
  require Adder

  Adder.define(1)
  Adder.define(5)
end

Test.add_1(1) # => 1 + 5
Test.add_5(1) # => 1 + 5
