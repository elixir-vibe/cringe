defmodule Cringe.Widgets.TabsTest do
  use ExUnit.Case, async: true

  use Cringe.Case

  alias Cringe.Widgets.Tabs
  alias Cringe.Widgets.Tabs.State
  alias Cringe.Widgets.Tabs.Tab

  test "builds tabs as structs" do
    state =
      State.new([%{id: :one, label: "One", content: "first"}, Tab.new(id: :two, label: "Two")])

    assert State.selected_tab(state) == %Tab{id: :one, label: "One", content: "first"}
  end

  test "renders selected tab and content" do
    state =
      State.new([
        %{id: :one, label: "One", content: "first"},
        %{id: :two, label: "Two", content: "second"}
      ])

    assert tabs(state: state) |> render() |> String.trim_trailing() == "[ One ]   Two  \nfirst"
  end

  test "renders document content" do
    state = State.new([%{id: :one, label: "One", content: Cringe.text("first", color: :green)}])

    assert tabs(state: state) |> render() |> String.trim_trailing() == "[ One ]\nfirst"
  end

  test "clips tab bar to width" do
    state = State.new([%{id: :one, label: "One"}, %{id: :two, label: "Two"}])

    assert render(tabs(state: state, width: 8)) == "[ One ] "
  end

  test "moves selected tabs" do
    state = State.new([%{id: :one, label: "One"}, %{id: :two, label: "Two"}])

    assert Tabs.update(state, Cringe.Event.key(:right)) == {:ok, %{state | selected: 1}}
    assert Tabs.update(%{state | selected: 1}, Cringe.Event.key(:left)) == {:ok, state}
  end

  test "selects tabs by id" do
    state = State.new([%{id: :one, label: "One"}, %{id: :two, label: "Two"}])

    assert State.select(state, :two).selected == 1
    assert State.select(state, :missing) == state
  end

  test "returns selected tab" do
    state = State.new([%{id: :one, label: "One"}])

    assert Tabs.update(state, Cringe.Event.key(:enter)) ==
             {:select, State.selected_tab(state), state}
  end

  test "accepts custom keymaps" do
    state = State.new([%{id: :one, label: "One"}, %{id: :two, label: "Two"}])
    keymap = Cringe.Keymap.new(next: [:tab])

    assert Tabs.update(state, Cringe.Event.key(:right), keymap) == :ignored
    assert Tabs.update(state, Cringe.Event.key(:tab), keymap) == {:ok, %{state | selected: 1}}
  end
end
