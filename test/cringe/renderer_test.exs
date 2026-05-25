defmodule Cringe.RendererTest do
  use ExUnit.Case, async: true

  import Cringe
  import Cringe.Test, only: [assert_render: 2]

  test "renders text documents" do
    assert text("hello") |> render() == "hello"
  end

  test "clips rendered text to width" do
    assert text("hello") |> render(width: 3) == "hel"
  end

  test "clips rendered text to height" do
    document = text("one\ntwo\nthree")

    assert render(document, height: 2) == "one\ntwo"
  end

  test "clips by grapheme" do
    assert text("🥲 cringe") |> render(width: 3) == "🥲 c"
  end

  test "renders vertical stacks with gaps" do
    document =
      column(
        [
          text("one"),
          text("two")
        ],
        gap: 1
      )

    assert_render(document, """
    one

    two
    """)
  end

  test "renders horizontal stacks with aligned multiline children" do
    document =
      row(
        [
          text("a\nbb"),
          text("ccc")
        ],
        gap: 2
      )

    assert_render(document, """
    a   ccc
    bb     
    """)
  end

  test "renders rounded boxes" do
    document = text("hi") |> box(padding: 1)

    assert_render(document, """
    ╭────╮
    │    │
    │ hi │
    │    │
    ╰────╯
    """)
  end

  test "renders square boxes" do
    document = text("hi") |> box(border: :square)

    assert_render(document, """
    +--+
    |hi|
    +--+
    """)
  end

  test "applies fixed width and alignment" do
    assert text("hi", width: 6, align: :right) |> render() == "    hi"
    assert text("hi", width: 6, align: :center) |> render() == "  hi  "
  end

  test "distributes row grow width" do
    document =
      row(
        [
          text("a", width: 3),
          text("b", grow: 1)
        ],
        gap: 1,
        width: 8
      )

    assert render(document) == "a   b   "
  end
end
