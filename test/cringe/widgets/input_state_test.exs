defmodule Cringe.Widgets.Input.StateTest do
  use ExUnit.Case, async: true

  alias Cringe.Widgets.Input.State

  test "inserts at the cursor" do
    state = State.new("ac", cursor: 1)

    assert State.insert(state, "b") == State.new("abc", cursor: 2)
  end

  test "backspaces before the cursor" do
    state = State.new("abc", cursor: 2)

    assert State.backspace(state) == State.new("ac", cursor: 1)
  end

  test "deletes after the cursor" do
    state = State.new("abc", cursor: 1)

    assert State.delete(state) == State.new("ac", cursor: 1)
  end

  test "moves within bounds" do
    state = State.new("abc", cursor: 1)

    assert state |> State.move(-10) |> State.cursor() == 0
    assert state |> State.move(10) |> State.cursor() == 3
  end

  test "moves to line bounds" do
    state = State.new("abc", cursor: 1)

    assert state |> State.home() |> State.cursor() == 0
    assert state |> State.end_of_line() |> State.cursor() == 3
  end
end
