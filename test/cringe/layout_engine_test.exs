defmodule Cringe.Layout.EngineTest do
  use ExUnit.Case, async: true

  import Cringe

  alias Cringe.Layout.Engine

  test "returns a positioned layout tree" do
    document =
      box padding: 1 do
        column gap: 1 do
          text("one")
          text("two")
        end
      end

    node = Engine.layout(document)

    assert node.rect.width == 7
    assert node.rect.height == 7
    assert [box_child] = node.children
    assert box_child.rect.x == 2
    assert box_child.rect.y == 2
    assert [first, second] = box_child.children
    assert first.rect.y == 0
    assert second.rect.y == 2
  end

  test "applies root constraints to layout lines" do
    node = Engine.layout(text("hello\nworld"), width: 3, height: 1)

    assert node.lines == ["hel"]
    assert node.rect.width == 3
    assert node.rect.height == 1
  end
end
