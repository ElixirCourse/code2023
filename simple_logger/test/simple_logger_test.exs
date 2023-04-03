defmodule SimpleLoggerTest do
  use ExUnit.Case
  doctest SimpleLogger

  def bla do
    :shit
  end

  test "greets the world" do
    assert bla()
  end
end
