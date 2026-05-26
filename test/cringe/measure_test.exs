defmodule Cringe.MeasureTest do
  use ExUnit.Case, async: true

  alias Cringe.Measure

  test "counts terminal cells" do
    assert Measure.width("a") == 1
    assert Measure.width("🚀") == 2
    assert Measure.width("⚗️") == 2
    assert Measure.width("東") == 2
    assert Measure.width("é") == 1
    assert Measure.width("🏳️‍🌈") == 2
  end

  test "takes text by terminal cells" do
    assert Measure.take("ab🚀cd", 4) == "ab🚀"
    assert Measure.take("ab🚀cd", 3) == "ab"
  end

  test "pads by terminal cells" do
    assert Measure.pad("🚀", 4) == "🚀  "
  end
end
