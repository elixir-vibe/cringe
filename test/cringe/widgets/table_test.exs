defmodule Cringe.Widgets.TableTest do
  use ExUnit.Case, async: true

  use Cringe.Case

  alias Cringe.Widgets.Table
  alias Cringe.Widgets.Table.Column
  alias Cringe.Widgets.Table.Row
  alias Cringe.Widgets.Table.State

  @columns [
    %{id: :name, label: "Name", width: 8},
    %{id: :count, label: "Count", width: 5, align: :right}
  ]

  test "builds columns and rows as structs" do
    assert Column.new(id: :name) == %Column{id: :name, label: "name", width: nil, align: :left}
    assert Row.new(id: :one, cells: [name: "One"]).cells == %{name: "One"}
  end

  test "renders table headers and rows" do
    rows = [%{name: "Alpha", count: 2}, %{name: "Beta", count: 12}]

    assert table(columns: @columns, rows: rows) |> render() |> trimmed_lines() == [
             "  Name      Count",
             "  Alpha         2",
             "  Beta         12"
           ]
  end

  test "renders selected rows" do
    state = State.new([%{name: "Alpha", count: 2}, %{name: "Beta", count: 12}], selected: 1)

    assert table(columns: @columns, state: state) |> render() |> trimmed_lines() == [
             "  Name      Count",
             "  Alpha         2",
             "› Beta         12"
           ]
  end

  test "clips long cells" do
    rows = [%{name: "Very long name", count: 2}]

    assert table(columns: @columns, rows: rows, header: false)
           |> render()
           |> String.trim_trailing() ==
             "  Very lon      2"
  end

  test "moves selection" do
    state = State.new([%{name: "A"}, %{name: "B"}], selected: 0)

    assert Table.update(state, Cringe.Event.key(:down)) == {:ok, %{state | selected: 1}}
    assert Table.update(%{state | selected: 1}, Cringe.Event.key(:up)) == {:ok, state}
  end

  test "returns selected rows" do
    state = State.new([%{id: :a, name: "A"}], selected: 0)

    assert Table.update(state, Cringe.Event.key(:enter)) ==
             {:select, State.selected_row(state), state}
  end

  test "accepts custom keymaps" do
    state = State.new([%{name: "A"}, %{name: "B"}], selected: 0)
    keymap = Cringe.Keymap.new(next: [:tab])

    assert Table.update(state, Cringe.Event.key(:down), keymap) == :ignored
    assert Table.update(state, Cringe.Event.key(:tab), keymap) == {:ok, %{state | selected: 1}}
  end

  test "windows visible rows around selection" do
    state =
      1..5
      |> Enum.map(&%{name: "Row #{&1}"})
      |> State.new(selected: 3, max_visible: 3)

    assert table(columns: [%{id: :name, label: "Name", width: 5}], state: state, header: false)
           |> render()
           |> trimmed_lines() == ["  Row 3", "› Row 4", "  Row 5"]
  end

  defp trimmed_lines(document) do
    document
    |> String.split("\n")
    |> Enum.map(&String.trim_trailing/1)
  end
end
