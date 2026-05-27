defmodule Cringe.WidgetsTest do
  use ExUnit.Case, async: true

  use Cringe.Case

  alias Cringe.Widgets.Editor
  alias Cringe.Widgets.Editor.State, as: EditorState
  alias Cringe.Widgets.Input
  alias Cringe.Widgets.Input.State, as: InputState
  alias Cringe.Widgets.Select
  alias Cringe.Widgets.SelectList
  alias Cringe.Widgets.SelectList.{Item, State}

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
    state = InputState.new("abc", cursor: 1)

    assert frame(input(state: state, focused: true, width: 7)).cursor == {1, 4}
  end

  test "updates input values from text and backspace events" do
    assert Input.update("ab", Cringe.Event.text("c")) == {:ok, "abc"}
    assert Input.update("ab", Cringe.Event.key(:backspace)) == {:ok, "a"}
    assert Input.update("ab", Cringe.Event.key(:enter)) == :ignored
  end

  test "updates cursor-aware input state" do
    state = InputState.new("ac", cursor: 1)

    assert Input.update(state, Cringe.Event.text("b")) == {:ok, InputState.new("abc", cursor: 2)}
    assert Input.update(state, Cringe.Event.key(:right)) == {:ok, InputState.new("ac", cursor: 2)}
  end

  test "renders multiline editors" do
    assert_render(editor(value: "one\ntwo"), """
    one
    two
    """)
  end

  test "editors expose frame cursors when focused" do
    state = EditorState.new("one\ntwo", cursor_line: 1, cursor_col: 1)

    assert frame(editor(state: state, focused: true)).cursor == {2, 2}
  end

  test "editors render a viewport around the cursor" do
    state = EditorState.new("one\ntwo\nthree\nfour", cursor_line: 3, cursor_col: 2)

    assert editor(state: state, focused: true, height: 2) |> render() |> String.trim_trailing() ==
             "three\nfour"

    assert frame(editor(state: state, focused: true, height: 2)).cursor == {2, 3}
  end

  test "editor visible start follows cursor within bounds" do
    assert Editor.visible_start(EditorState.new("one\ntwo\nthree", cursor_line: 0), 2) == 0
    assert Editor.visible_start(EditorState.new("one\ntwo\nthree", cursor_line: 2), 2) == 1
    assert Editor.visible_start(EditorState.new("one\ntwo\nthree", cursor_line: 2), 10) == 0
  end

  test "editors render a horizontal viewport around the cursor" do
    state = EditorState.new("abcdef", cursor_col: 5)

    assert render(editor(state: state, focused: true, width: 3)) == "def"
    assert frame(editor(state: state, focused: true, width: 3)).cursor == {1, 3}
  end

  test "editor visible column start follows cursor within bounds" do
    assert Editor.visible_column_start(EditorState.new("abcdef", cursor_col: 0), 3) == 0
    assert Editor.visible_column_start(EditorState.new("abcdef", cursor_col: 5), 3) == 3
  end

  test "updates multiline editor state" do
    state = EditorState.new("ac", cursor_col: 1)

    assert Editor.update(state, Cringe.Event.text("b")) ==
             {:ok, EditorState.new("abc", cursor_col: 2)}

    assert Editor.update(state, Cringe.Event.key(:enter)) ==
             {:ok, EditorState.new("a\nc", cursor_line: 1, cursor_col: 0)}
  end

  test "editors accept a custom keymap" do
    state = EditorState.new("a")
    keymap = Cringe.Keymap.new(newline: [:tab])

    assert Editor.update(state, Cringe.Event.key(:enter), keymap) == :ignored

    assert Editor.update(state, Cringe.Event.key(:tab), keymap) ==
             {:ok, EditorState.new("a\n", cursor_line: 1, cursor_col: 0)}
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

  test "renders select list labels and aligned descriptions" do
    state =
      State.new([
        %Item{id: :short, label: "short", description: "short description", value: :short},
        %Item{
          id: :long,
          label: "very-long-command-name-that-needs-truncation",
          description: "long description",
          value: :long
        }
      ])

    rendered = render(select_list(state: state), width: 80)
    [first, second] = String.split(rendered, "\n")

    assert first =~ "short description"
    assert second =~ "long description"

    assert visible_column(first, "short description") ==
             visible_column(second, "long description")
  end

  test "select list normalizes multiline descriptions" do
    state =
      State.new([
        %{id: :test, label: "test", description: "Line one\nLine two\nLine three"}
      ])

    assert render(select_list(state: state), width: 80) =~ "Line one Line two Line three"
  end

  test "select list scrolls around the selected item" do
    state =
      1..6
      |> Enum.map(&%{id: &1, label: "item #{&1}"})
      |> State.new(selected: 4, max_visible: 3)

    assert render(select_list(state: state)) |> String.trim_trailing() ==
             Cringe.Assertions.clean_heredoc("""
               item 4
             › item 5
               item 6
               (5/6)
             """)
  end

  test "updates select list state and returns selected items" do
    state = State.new([%{id: :one, label: "one"}, %{id: :two, label: "two"}])

    assert {:ok, %State{selected: 1} = selected_state} =
             SelectList.update(state, Cringe.Event.key(:down))

    assert SelectList.update(selected_state, Cringe.Event.key(:enter)) ==
             {:select, State.selected_item(selected_state), selected_state}

    assert SelectList.update(selected_state, Cringe.Event.key(:escape)) ==
             {:cancel, selected_state}

    assert SelectList.update(selected_state, Cringe.Event.key(:c)) == :ignored

    assert SelectList.update(selected_state, Cringe.Event.key(:c, mods: [:ctrl])) ==
             {:cancel, selected_state}
  end

  test "select list accepts a custom keymap" do
    state = State.new([%{id: :one, label: "one"}, %{id: :two, label: "two"}])
    keymap = Cringe.Keymap.new(next: [:tab])

    assert SelectList.update(state, Cringe.Event.key(:down), keymap) == :ignored

    assert SelectList.update(state, Cringe.Event.key(:tab), keymap) ==
             {:ok, %{state | selected: 1}}
  end

  test "filters select list items" do
    state =
      [%{id: :one, label: "one"}, %{id: :two, label: "two"}]
      |> State.new()
      |> State.put_filter("tw")

    assert_render(select_list(state: state), """
    › two
    """)
  end

  defp visible_column(line, text) do
    line
    |> String.split(text, parts: 2)
    |> hd()
    |> Cringe.Measure.width()
  end
end
