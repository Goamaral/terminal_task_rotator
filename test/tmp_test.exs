defmodule TmpTest do
  use ExUnit.Case
  doctest Tmp

  test "greets the world" do
    assert Tmp.hello() == :world
  end
end
