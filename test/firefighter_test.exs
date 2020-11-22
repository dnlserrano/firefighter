defmodule FirefighterTest do
  use ExUnit.Case
  doctest Firefighter

  test "greets the world" do
    assert Firefighter.hello() == :world
  end
end
