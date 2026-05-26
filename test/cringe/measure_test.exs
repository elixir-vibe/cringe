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

  test "takes ANSI styled text without dropping active styles" do
    assert Measure.take("\e[31mhello\e[0m", 2) == "\e[31mhe\e[0m"
    assert Measure.take("\e[31mhello\e[0m", 20) == "\e[31mhello\e[0m"
  end

  test "preserves multiple SGR sequences while taking" do
    assert Measure.take("\e[1mhi \e[32mok\e[0m", 4) == "\e[1mhi \e[32mo\e[0m"
  end

  test "pads by terminal cells" do
    assert Measure.pad("🚀", 4) == "🚀  "
  end

  test "fits text to terminal cells" do
    assert Measure.fit("🚀", 4) == "🚀  "
    assert Measure.fit("ab🚀cd", 4) == "ab🚀"
    assert Measure.fit("ab🚀cd", 4, ellipsis?: true) == "ab…"
  end

  test "drops text by terminal cells" do
    assert Measure.drop("ab🚀cd", 4) == "cd"
    assert Measure.drop("ab🚀cd", 3) == "cd"
  end
end
