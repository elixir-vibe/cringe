defmodule Cringe.CanvasTest do
  use ExUnit.Case, async: true

  alias Cringe.Canvas

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
end
