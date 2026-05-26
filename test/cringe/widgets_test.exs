defmodule Cringe.WidgetsTest do
  use ExUnit.Case, async: true

  use Cringe.Case

  alias Cringe.Widgets.Input
  alias Cringe.Widgets.Input.State
  alias Cringe.Widgets.Select

  test "renders progress bars" do
    assert_render(progress(value: 0.5, width: 4), """
    [██░░]
    """)
  end

  test "renders spinners" do
    assert render(spinner(frame: 1, label: "Loading")) == "⠙ Loading"
  end

  test "renders input fields" do
    assert render(input(value: "abc", focused: true, width: 7)) == "> abc  "
  end

  test "input fields expose frame cursors when focused" do
    assert frame(input(value: "abc", focused: true, width: 7)).cursor == {1, 6}
  end

  test "input fields position cursors from input state" do
    state = State.new("abc", cursor: 1)

    assert frame(input(state: state, focused: true, width: 7)).cursor == {1, 4}
  end

  test "updates input values from text and backspace events" do
    assert Input.update("ab", Cringe.Event.text("c")) == {:ok, "abc"}
    assert Input.update("ab", Cringe.Event.key(:backspace)) == {:ok, "a"}
    assert Input.update("ab", Cringe.Event.key(:enter)) == :ignored
  end

  test "updates cursor-aware input state" do
    state = State.new("ac", cursor: 1)

    assert Input.update(state, Cringe.Event.text("b")) == {:ok, State.new("abc", cursor: 2)}
    assert Input.update(state, Cringe.Event.key(:right)) == {:ok, State.new("ac", cursor: 2)}
  end

  test "renders select lists" do
    assert_render(select(options: ["one", "two"], selected: 1), """
      one
    › two
    """)
  end

  test "renders focused select rows with style" do
    assert render(select(options: ["one", "two"], selected: 1, focused: true), ansi: true) ==
             "  one\n\e[1;36m› two\e[0m"
  end

  test "updates select indexes" do
    options = ["one", "two", "three"]

    assert Select.update(0, Cringe.Event.key(:down), options) == {:ok, 1}
    assert Select.update(1, Cringe.Event.key(:up), options) == {:ok, 0}
    assert Select.update(2, Cringe.Event.key(:down), options) == {:ok, 2}
    assert Select.update(0, Cringe.Event.key(:enter), options) == :ignored
  end
end
