defmodule Cringe.MeasureTest do
  use ExUnit.Case, async: true

  doctest Cringe.Measure

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

  test "slices text by terminal cells" do
    assert Measure.slice("abcdef", 1, 3) == "bcd"
    assert Measure.slice("ab🚀cd", 2, 2) == "🚀"
    assert Measure.slice("ab🚀cd", 3, 2) == "c"
  end

  test "preserves ANSI styles while slicing" do
    assert Measure.slice("\e[31mhello\e[0m", 1, 2) == "\e[31mel\e[0m"
  end

  test "pads by terminal cells" do
    assert Measure.pad("🚀", 4) == "🚀  "
  end

  test "fits text to terminal cells" do
    assert Measure.fit("🚀", 4) == "🚀  "
    assert Measure.fit("ab🚀cd", 4) == "ab🚀"
    assert Measure.fit("ab🚀cd", 4, ellipsis?: true) == "ab…"
  end

  test "chunks text by terminal cells" do
    assert Measure.chunks("a🚀b東c", 3) == ["a🚀", "b東", "c"]
  end

  test "wraps text by terminal cells" do
    assert Measure.wrap("hello world", 5) == ["hello", "world"]
    assert Measure.wrap("a🚀b東c", 3) == ["a🚀", "b東", "c"]
    assert Measure.wrap("one\ntwo", 10) == ["one", "two"]
  end

  test "wraps empty lines explicitly" do
    assert Measure.wrap("one\n\ntwo", 10) == ["one", "", "two"]
  end

  test "wrap normalizes leading and trailing whitespace at breaks" do
    assert Measure.wrap("  hello world  ", 5) == ["hello", "world"]
    assert Measure.wrap("hello   world", 8) == ["hello", "world"]
  end

  test "wrap strips ANSI styling before measuring" do
    assert Measure.wrap("\e[31mhello world\e[0m", 5) == ["hello", "world"]
  end

  test "drops text by terminal cells" do
    assert Measure.drop("ab🚀cd", 4) == "cd"
    assert Measure.drop("ab🚀cd", 3) == "cd"
  end
end
