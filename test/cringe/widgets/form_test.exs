defmodule Cringe.Widgets.FormTest do
  use ExUnit.Case, async: true

  use Cringe.Case

  alias Cringe.Widgets.Form
  alias Cringe.Widgets.Form.Field
  alias Cringe.Widgets.Form.State
  alias Cringe.Widgets.Input

  test "builds form state from struct fields" do
    state = State.new([Field.input(:name), Field.select(:role, ["Admin", "Viewer"])])

    assert State.current_field(state).id == :name
    assert State.field_state(state, :role) == 0
  end

  test "renders labels and focused controls" do
    state =
      State.new([
        Field.input(:name, value: "Dan"),
        Field.select(:role, ["Admin", "Viewer"], selected: 1)
      ])

    assert form(state: state, gap: 0) |> render() |> trimmed_lines() == [
             "Name",
             "> Dan",
             "Role",
             "  Admin",
             "› Viewer"
           ]
  end

  test "moves focus with tab and shift tab" do
    state = State.new([Field.input(:name), Field.input(:email)])

    assert {:ok, state} = Form.update(state, Cringe.Event.key(:tab))
    assert State.current_field(state).id == :email

    assert {:ok, state} = Form.update(state, Cringe.Event.key(:tab, mods: [:shift]))
    assert State.current_field(state).id == :name
  end

  test "delegates input updates to the focused field" do
    state = State.new([Field.input(:name), Field.input(:email)])

    assert {:ok, state} = Form.update(state, Cringe.Event.text("D"))
    assert State.field_state(state, :name) == Input.State.new("D")
    assert State.field_state(state, :email) == Input.State.new("")
  end

  test "delegates select updates to the focused field" do
    state =
      State.new([Field.input(:name), Field.select(:role, ["Admin", "Viewer"])], current: :role)

    assert {:ok, state} = Form.update(state, Cringe.Event.key(:down))
    assert State.field_state(state, :role) == 1
  end

  test "delegates editor updates to the focused field" do
    state = State.new([Field.editor(:notes, value: "one")])

    assert {:ok, state} = Form.update(state, Cringe.Event.key(:enter))
    assert State.field_state(state, :notes) == Cringe.Widgets.Editor.State.new("one\n")
  end

  test "returns ignored when the focused field ignores an event" do
    state = State.new([Field.input(:name)])

    assert Form.update(state, Cringe.Event.key(:enter)) == :ignored
  end

  test "fields can be updated directly" do
    state = State.new([Field.input(:name)])
    field = Field.input(:name, state: Input.State.new("Dan"))

    assert State.put_field(state, field) |> State.field_state(:name) == Input.State.new("Dan")
  end

  defp trimmed_lines(document) do
    document
    |> String.split("\n")
    |> Enum.map(&String.trim_trailing/1)
  end
end
