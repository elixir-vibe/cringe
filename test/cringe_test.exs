defmodule CringeTest do
  use ExUnit.Case, async: true

  doctest Cringe

  test "module is available" do
    assert Code.ensure_loaded?(Cringe)
  end
end
