defmodule Cringe.StyleTest do
  use ExUnit.Case, async: true

  test "renders plain text by default" do
    assert Cringe.text("ok", color: :green, bold: true) |> Cringe.render() == "ok"
  end

  test "renders ANSI styles when enabled" do
    assert Cringe.text("ok", color: :green, bold: true) |> Cringe.render(ansi: true) ==
             "\e[1;32mok\e[0m"
  end
end
