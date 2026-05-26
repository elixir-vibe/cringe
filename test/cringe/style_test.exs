defmodule Cringe.StyleTest do
  use ExUnit.Case, async: true

  use Cringe.Case

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

  test "provides shared style variants" do
    assert Cringe.Style.variant(:focused, color: :yellow) == [bold: true, color: :yellow]
    assert Cringe.Theme.input()[:placeholder_color] == :bright_black
  end
end
