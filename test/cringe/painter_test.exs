defmodule Cringe.PainterTest do
  use ExUnit.Case, async: true

  import Cringe

  test "first paint clears and writes all lines" do
    painter = Cringe.Painter.new(20, 5)
    {output, painter} = Cringe.Painter.render(painter, text("one\ntwo"))

    text = IO.iodata_to_binary(output)
    assert text =~ "\e[H\e[2J"
    assert text =~ "one"
    assert text =~ "two"

    assert painter.previous == [
             "one                 ",
             "two                 ",
             "                    ",
             "                    ",
             "                    "
           ]
  end

  test "subsequent paints write changed lines only" do
    painter = Cringe.Painter.new(20, 5)
    {_output, painter} = Cringe.Painter.render(painter, text("one\ntwo"))
    {output, painter} = Cringe.Painter.render(painter, text("one\nthree"))

    text = IO.iodata_to_binary(output)
    assert text =~ "\e[2;1H"
    assert text =~ "three"
    refute text =~ "\e[1;1H\e[2K"

    assert painter.previous == [
             "one                 ",
             "three               ",
             "                    ",
             "                    ",
             "                    "
           ]
  end

  test "shows and moves cursor when frame has cursor" do
    painter = Cringe.Painter.new(20, 5)
    frame = Cringe.frame(input(value: "abc", focused: true))
    {output, painter} = Cringe.Painter.render(painter, frame)

    text = IO.iodata_to_binary(output)
    assert text =~ "\e[?25h"
    assert text =~ "\e[1;6H"
    assert painter.cursor_visible?
    assert painter.cursor == {1, 6}
  end

  test "hides cursor when the next frame has no cursor" do
    painter = Cringe.Painter.new(20, 5)
    frame = Cringe.frame(input(value: "abc", focused: true))
    {_output, painter} = Cringe.Painter.render(painter, frame)
    {output, painter} = Cringe.Painter.render(painter, text("done"))

    assert IO.iodata_to_binary(output) =~ "\e[?25l"
    refute painter.cursor_visible?
    assert painter.cursor == nil
  end

  test "moves cursor without repainting unchanged lines" do
    painter = Cringe.Painter.new(20, 5)

    {_output, painter} =
      Cringe.Painter.render(painter, Cringe.Frame.new(["hello"], cursor: {1, 2}))

    {output, painter} =
      Cringe.Painter.render(painter, Cringe.Frame.new(["hello"], cursor: {1, 4}))

    assert IO.iodata_to_binary(output) == "\e[1;4H"
    assert painter.cursor == {1, 4}
  end

  test "does not write unchanged cursorless frames" do
    painter = Cringe.Painter.new(20, 5)
    {_output, painter} = Cringe.Painter.render(painter, text("done"))
    {output, _painter} = Cringe.Painter.render(painter, text("done"))

    assert output == []
  end
end
