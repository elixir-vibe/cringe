defmodule Cringe.Renderer.DrawTest do
  use ExUnit.Case, async: true

  use Cringe.Case

  alias Cringe.Layout.Engine
  alias Cringe.Renderer.Draw

  test "draws layout nodes into frames" do
    frame =
      text("hi")
      |> Engine.layout()
      |> Draw.frame(width: 4, height: 2)

    assert frame.lines == ["hi  ", "    "]
  end

  test "preserves layout cursors" do
    frame =
      input(value: "hi", focused: true)
      |> Engine.layout()
      |> Draw.frame(width: 10, height: 1)

    assert frame.cursor == {1, 5}
  end

  test "draws stack children from geometry" do
    frame =
      column gap: 1 do
        text("one")
        text("two")
      end
      |> Engine.layout()
      |> Draw.frame(width: 5, height: 3)

    assert frame.lines == ["one  ", "     ", "two  "]
  end
end
