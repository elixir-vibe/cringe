defmodule Cringe.RendererTest do
  use ExUnit.Case, async: true

  test "renders text documents" do
    assert Cringe.text("hello") |> Cringe.render() == "hello"
  end

  test "clips rendered text to width" do
    assert Cringe.text("hello") |> Cringe.render(width: 3) == "hel"
  end

  test "clips rendered text to height" do
    document = Cringe.text("one\ntwo\nthree")

    assert Cringe.render(document, height: 2) == "one\ntwo"
  end

  test "clips by grapheme" do
    assert Cringe.text("🥲 cringe") |> Cringe.render(width: 3) == "🥲 c"
  end

  test "renders vertical stacks with gaps" do
    document =
      Cringe.column(
        [
          Cringe.text("one"),
          Cringe.text("two")
        ],
        gap: 1
      )

    assert Cringe.render(document) == "one\n\ntwo"
  end

  test "renders horizontal stacks with aligned multiline children" do
    document =
      Cringe.row(
        [
          Cringe.text("a\nbb"),
          Cringe.text("ccc")
        ],
        gap: 2
      )

    assert Cringe.render(document) == "a   ccc\nbb     "
  end

  test "renders rounded boxes" do
    document = Cringe.text("hi") |> Cringe.box(padding: 1)

    assert Cringe.render(document) == "╭────╮\n│    │\n│ hi │\n│    │\n╰────╯"
  end

  test "renders square boxes" do
    document = Cringe.text("hi") |> Cringe.box(border: :square)

    assert Cringe.render(document) == "+--+\n|hi|\n+--+"
  end
end
