defmodule Cringe.Widgets.MenuTest do
  use ExUnit.Case, async: true

  use Cringe.Case

  alias Cringe.Widgets.Menu
  alias Cringe.Widgets.Menu.Entry
  alias Cringe.Widgets.Menu.Item
  alias Cringe.Widgets.Menu.State

  test "builds menu entries as structs" do
    state = State.new([{:section, "File"}, %{id: :open, label: "Open"}, :separator])

    assert state.entries == [
             %Entry{kind: :section, label: "File"},
             %Entry{kind: :item, item: %Item{id: :open, label: "Open", value: :open}},
             %Entry{kind: :separator}
           ]
  end

  test "selects first enabled item by default" do
    state = State.new([{:section, "File"}, %{id: :open, label: "Open"}])

    assert state.selected == 1
    assert State.selected_item(state).id == :open
  end

  test "renders sections separators shortcuts and descriptions" do
    state =
      State.new([
        {:section, "File"},
        %{id: :open, label: "Open", shortcut: "Enter", description: "Open selected file"},
        :separator,
        %{id: :delete, label: "Delete", disabled?: true}
      ])

    assert menu(state: state, width: 60) |> render() |> trimmed_lines() == [
             "File",
             "› Open     Enter  Open selected file",
             "────────────────────────────────────────────────────────────",
             "  Delete"
           ]
  end

  test "moves across enabled items and skips disabled entries" do
    state =
      State.new([
        %{id: :one, label: "One"},
        %{id: :disabled, label: "Disabled", disabled?: true},
        %{id: :two, label: "Two"}
      ])

    assert Menu.update(state, Cringe.Event.key(:down)) == {:ok, %{state | selected: 2}}
    assert Menu.update(%{state | selected: 2}, Cringe.Event.key(:up)) == {:ok, state}
  end

  test "returns selected and cancelled results" do
    state = State.new([%{id: :open, label: "Open"}])

    assert Menu.update(state, Cringe.Event.key(:enter)) ==
             {:select, State.selected_item(state), state}

    assert Menu.update(state, Cringe.Event.key(:escape)) == {:cancel, state}
  end

  test "accepts custom keymaps" do
    state = State.new([%{id: :one, label: "One"}, %{id: :two, label: "Two"}])
    keymap = Cringe.Keymap.new(next: [:tab])

    assert Menu.update(state, Cringe.Event.key(:down), keymap) == :ignored
    assert Menu.update(state, Cringe.Event.key(:tab), keymap) == {:ok, %{state | selected: 1}}
  end

  test "windows visible entries around selection" do
    state =
      1..5
      |> Enum.map(&%{id: &1, label: "Item #{&1}"})
      |> State.new(selected: 3, max_visible: 3)

    assert menu(state: state) |> render() |> trimmed_lines() == [
             "  Item 3",
             "› Item 4",
             "  Item 5",
             "  (4/5)"
           ]
  end

  test "renders empty state when there are no selectable items" do
    state = State.new([{:section, "Empty"}])

    assert render(menu(state: state)) == "  No menu items"
  end

  defp trimmed_lines(document) do
    document
    |> String.split("\n")
    |> Enum.map(&String.trim_trailing/1)
  end
end
