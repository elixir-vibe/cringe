defmodule Cringe.StyleTest do
  use ExUnit.Case, async: true

  import Cringe

  test "renders plain text by default" do
    assert text("ok", color: :green, bold: true) |> render() == "ok"
  end

  test "renders ANSI styles when enabled" do
    assert text("ok", color: :green, bold: true) |> render(ansi: true) == "\e[1;32mok\e[0m"
  end
end
