defmodule Cringe.Widgets.Editor.ViewportTest do
  use ExUnit.Case, async: true

  alias Cringe.Widgets.Editor.State
  alias Cringe.Widgets.Editor.Viewport

  test "computes visible line start" do
    state = State.new("one\ntwo\nthree", cursor_line: 2)

    assert Viewport.line_start(state, 2) == 1
    assert Viewport.line_start(state, 10) == 0
  end

  test "computes visible column start in terminal cells" do
    state = State.new("ab🚀cd", cursor_col: 4)

    assert Viewport.column_start(state, 3) == 3
  end

  test "computes cursor column relative to viewport" do
    state = State.new("abcdef", cursor_col: 5)
    viewport = Viewport.new(state, 3, 1)

    assert viewport == %Viewport{line: 0, column: 3, width: 3, height: 1}
    assert Viewport.cursor_column(state, viewport) == 3
  end
end
