defmodule Cringe.Renderer.Draw.ContextTest do
  use ExUnit.Case, async: true

  alias Cringe.Canvas
  alias Cringe.Rect
  alias Cringe.Renderer.Draw.Context

  test "clips block writes" do
    context =
      Canvas.new(6, 3)
      |> Context.new()
      |> Context.clip(Rect.new(2, 1, 3, 1))
      |> Context.put_block(0, 0, ["abcdef", "ghijkl"])

    assert Canvas.lines(context.canvas) == [
             "      ",
             "  ijk ",
             "      "
           ]
  end

  test "intersects nested clips" do
    context =
      Canvas.new(8, 4)
      |> Context.new()
      |> Context.clip(Rect.new(1, 1, 5, 2))
      |> Context.clip(Rect.new(3, 0, 5, 3))
      |> Context.put_block(0, 0, ["abcdefgh", "ijklmnop", "qrstuvwx"])

    assert Canvas.lines(context.canvas) == [
             "        ",
             "   lmn  ",
             "   tuv  ",
             "        "
           ]
  end
end
