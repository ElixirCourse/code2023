defmodule BooksTest do
  use ExUnit.Case
  doctest Books

  test "greets the world" do
    assert Books.hello() == :world
  end
end
