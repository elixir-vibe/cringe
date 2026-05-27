defmodule Cringe.Widgets.DialogTest do
  use ExUnit.Case, async: true

  use Cringe.Case

  alias Cringe.Widgets.Dialog
  alias Cringe.Widgets.Dialog.Action
  alias Cringe.Widgets.Dialog.State

  test "builds actions as structs" do
    state = State.new([%{id: :ok, label: "OK"}, Action.new(id: :cancel, label: "Cancel")])

    assert State.selected_action(state) == %Action{id: :ok, label: "OK", value: :ok}
  end

  test "renders title body and actions" do
    state = State.new([%{id: :cancel, label: "Cancel"}, %{id: :ok, label: "OK"}], selected: 1)

    text =
      dialog(title: "Delete item?", body: "This cannot be undone.", state: state, width: 30)
      |> render()
      |> String.split("\n")
      |> Enum.map_join("\n", &String.trim_trailing/1)

    assert text =~ "Delete item?"
    assert text =~ "This cannot be undone."
    assert text =~ "  Cancel   [ OK ]"
  end

  test "wraps long body text" do
    rendered = dialog(body: "one two three", actions: [], width: 7) |> render()

    assert rendered =~ "one two"
    assert rendered =~ "three"
  end

  test "updates selected action" do
    state = State.new([%{id: :cancel, label: "Cancel"}, %{id: :ok, label: "OK"}])

    assert Dialog.update(state, Cringe.Event.key(:right)) == {:ok, %{state | selected: 1}}
    assert Dialog.update(%{state | selected: 1}, Cringe.Event.key(:left)) == {:ok, state}
  end

  test "returns selected and cancelled results" do
    state = State.new([%{id: :ok, label: "OK"}])

    assert Dialog.update(state, Cringe.Event.key(:enter)) ==
             {:select, State.selected_action(state), state}

    assert Dialog.update(state, Cringe.Event.key(:escape)) == {:cancel, state}
  end

  test "accepts custom keymaps" do
    state = State.new([%{id: :cancel, label: "Cancel"}, %{id: :ok, label: "OK"}])
    keymap = Cringe.Keymap.new(next: [:tab], select: [:space])

    assert Dialog.update(state, Cringe.Event.key(:right), keymap) == :ignored
    assert Dialog.update(state, Cringe.Event.key(:tab), keymap) == {:ok, %{state | selected: 1}}
  end
end
