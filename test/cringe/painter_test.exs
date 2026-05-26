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

  test "moves cursor after painting frame" do
    painter = Cringe.Painter.new(20, 5)
    frame = Cringe.frame(input(value: "abc", focused: true))
    {output, _painter} = Cringe.Painter.render(painter, frame)

    assert IO.iodata_to_binary(output) =~ "\e[1;6H"
  end
end
