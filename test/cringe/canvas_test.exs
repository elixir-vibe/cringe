defmodule Cringe.CanvasTest do
  use ExUnit.Case, async: true

  alias Cringe.Canvas
  alias Cringe.Rect

  test "puts text on a fixed-size surface" do
    canvas =
      Canvas.new(10, 3)
      |> Canvas.put(0, 0, "hello")
      |> Canvas.put(2, 1, "x")

    assert Canvas.lines(canvas) == [
             "hello     ",
             "  x       ",
             "          "
           ]
  end

  test "clips text to canvas bounds" do
    canvas =
      Canvas.new(5, 2)
      |> Canvas.put(3, 0, "hello")
      |> Canvas.put(0, 4, "ignored")

    assert Canvas.lines(canvas) == ["   he", "     "]
  end

  test "overwrites existing visible cells" do
    canvas =
      Canvas.new(8, 1)
      |> Canvas.put(0, 0, "abcdef")
      |> Canvas.put(2, 0, "XY")

    assert Canvas.lines(canvas) == ["abXYef  "]
  end

  test "preserves ANSI escapes in full-line writes" do
    line = "\e[1;32mok\e[0m"

    assert Canvas.new(4, 1) |> Canvas.put(0, 0, line) |> Canvas.lines() == ["\e[1;32mok\e[0m  "]
  end

  test "resets clipped ANSI full-line writes" do
    line = "\e[1;32mhello\e[0m"

    assert Canvas.new(3, 1) |> Canvas.put(0, 0, line) |> Canvas.lines() == ["\e[1;32mhel\e[0m"]
  end

  test "replaces blocks with a full-line fast path" do
    canvas =
      Canvas.new(6, 4)
      |> Canvas.put_block(0, 1, ["one", "two", "three", "ignored"])

    assert Canvas.lines(canvas) == [
             "      ",
             "one   ",
             "two   ",
             "three "
           ]
  end

  test "clips block writes to a rectangle" do
    canvas =
      Canvas.new(8, 4)
      |> Canvas.put_block(1, 1, ["abcdef", "ghijkl", "mnopqr"], clip: Rect.new(3, 2, 3, 1))

    assert Canvas.lines(canvas) == [
             "        ",
             "        ",
             "   ijk  ",
             "        "
           ]
  end
end
