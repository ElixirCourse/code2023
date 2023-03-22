defmodule AsynchTest do
  use ExUnit.Case
  doctest Asynch

  test "greets the world" do
    assert Asynch.hello() == :world
  end
end
