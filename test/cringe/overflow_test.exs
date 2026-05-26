defmodule Cringe.OverflowTest do
  use ExUnit.Case, async: true

  use Cringe.Case

  test "clips box content when overflow is hidden" do
    document =
      text("one\ntwo\nthree")
      |> box(height: 4, overflow: :hidden)

    assert_render(document, """
    ╭───╮
    │one│
    │two│
    ╰───╯
    """)
  end

  test "scrolls clipped box content" do
    document =
      text("one\ntwo\nthree")
      |> box(height: 4, overflow: :hidden, scroll_y: 1)

    assert_render(document, """
    ╭─────╮
    │two  │
    │three│
    ╰─────╯
    """)
  end

  test "clips scrolled cursors outside the visible content rect" do
    document =
      input(value: "abc", focused: true)
      |> column([
        text("second")
      ])
      |> box(height: 3, overflow: :hidden, scroll_y: 1)

    assert frame(document).cursor == nil
  end
end
