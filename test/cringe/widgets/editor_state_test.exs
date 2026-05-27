defmodule Cringe.Widgets.Editor.StateTest do
  use ExUnit.Case, async: true

  alias Cringe.Widgets.Editor.State

  test "builds state from text" do
    assert State.new("one\ntwo") == %State{lines: ["one", "two"], cursor_line: 1, cursor_col: 3}
  end

  test "inserts text at the cursor" do
    state = State.new("ac", cursor_col: 1)

    assert State.insert(state, "b") == State.new("abc", cursor_col: 2)
  end

  test "inserts multiline text at the cursor" do
    state = State.new("ac", cursor_col: 1)

    assert State.insert(state, "b\nc") == State.new("ab\ncc", cursor_line: 1, cursor_col: 1)
  end

  test "backspaces within and across lines" do
    assert "abc" |> State.new(cursor_col: 2) |> State.backspace() ==
             State.new("ac", cursor_col: 1)

    assert "one\ntwo"
           |> State.new(cursor_line: 1, cursor_col: 0)
           |> State.backspace() == State.new("onetwo", cursor_col: 3)
  end

  test "deletes within and across lines" do
    assert "abc" |> State.new(cursor_col: 1) |> State.delete() == State.new("ac", cursor_col: 1)

    assert "one\ntwo"
           |> State.new(cursor_line: 0, cursor_col: 3)
           |> State.delete() == State.new("onetwo", cursor_col: 3)
  end

  test "moves across line boundaries" do
    state = State.new("one\ntwo", cursor_line: 1, cursor_col: 0)

    assert State.move(state, :left) == State.new("one\ntwo", cursor_line: 0, cursor_col: 3)
    assert State.move(state, :right) == State.new("one\ntwo", cursor_line: 1, cursor_col: 1)
  end

  test "moves vertically and clamps the cursor column" do
    state = State.new("long\nx", cursor_line: 0, cursor_col: 4)

    assert State.move(state, :down) == State.new("long\nx", cursor_line: 1, cursor_col: 1)
  end

  test "returns joined value" do
    assert "one\ntwo" |> State.new() |> State.value() == "one\ntwo"
  end
end
