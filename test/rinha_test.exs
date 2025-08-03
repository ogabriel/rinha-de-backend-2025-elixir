defmodule RinhaTest do
  use ExUnit.Case
  doctest Rinha

  test "greets the world" do
    assert Rinha.hello() == :world
  end
end
