defmodule Cringe.Renderer.Draw.BoxTest do
  use ExUnit.Case, async: true

  alias Cringe.Canvas
  alias Cringe.Rect
  alias Cringe.Renderer.Draw.Box

  test "draws rounded borders" do
    canvas =
      Canvas.new(6, 4)
      |> Box.border(Rect.new(0, 0, 6, 4), :rounded)

    assert Canvas.lines(canvas) == [
             "╭────╮",
             "│    │",
             "│    │",
             "╰────╯"
           ]
  end

  test "draws square borders" do
    canvas =
      Canvas.new(4, 3)
      |> Box.border(Rect.new(0, 0, 4, 3), :square)

    assert Canvas.lines(canvas) == [
             "+--+",
             "|  |",
             "+--+"
           ]
  end

  test "computes content rectangles" do
    assert Box.content_rect(Rect.new(0, 0, 10, 6), 1, :rounded) == Rect.new(2, 2, 6, 2)
    assert Box.content_rect(Rect.new(0, 0, 10, 6), 1, false) == Rect.new(1, 1, 8, 4)
  end
end
