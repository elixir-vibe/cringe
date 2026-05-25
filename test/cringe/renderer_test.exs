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
end
