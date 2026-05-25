defmodule Cringe.StyleTest do
  use ExUnit.Case, async: true

  import Cringe
  import Cringe.Test, only: [assert_render: 3]

  test "renders plain text by default" do
    assert text("ok", color: :green, bold: true) |> render() == "ok"
  end

  test "renders ANSI styles when enabled" do
    assert text("ok", color: :green, bold: true) |> render(ansi: true) == "\e[1;32mok\e[0m"
  end

  test "measures styled text by visible width" do
    document = box(text("ok", color: :green, bold: true), padding: 1)

    assert_render(
      document,
      """
      ╭────╮
      │    │
      │ \e[1;32mok\e[0m │
      │    │
      ╰────╯
      """,
      ansi: true
    )
  end
end
