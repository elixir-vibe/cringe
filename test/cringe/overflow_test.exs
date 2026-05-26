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

  test "clips nested overflow boxes" do
    document =
      text("alpha\nbeta\ngamma")
      |> box(height: 4, overflow: :hidden, scroll_y: 1)
      |> box(height: 6, overflow: :hidden)

    assert_render(document, """
    ╭───────╮
    │╭─────╮│
    ││beta ││
    ││gamma││
    │╰─────╯│
    ╰───────╯
    """)
  end

  test "clips wide graphemes at box edges" do
    document =
      text("a🚀b")
      |> box(width: 4, overflow: :hidden)

    assert_render(document, """
    ╭──╮
    │a │
    ╰──╯
    """)
  end

  test "keeps styles balanced inside clipped overflow" do
    rendered =
      text("hello", color: :red, width: 2)
      |> box(width: 4, overflow: :hidden)
      |> render(ansi: true)

    assert rendered =~ "\e[31mhe\e[0m"
  end
end
