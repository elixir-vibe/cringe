defmodule Cringe.LayoutRegionsTest do
  use ExUnit.Case, async: true

  use Cringe.Case

  alias Cringe.Layout
  alias Cringe.Layout.Engine

  test "finds layout nodes by document id" do
    node =
      box padding: 1 do
        column gap: 1 do
          input(id: :name, value: "Dan", focused: true)
          select(id: :role, options: ["Admin", "User"], selected: 1)
        end
      end
      |> Engine.layout()

    assert Layout.find(node, :name).id == :name
    assert Layout.find(node, :role).id == :role
    assert Layout.find(node, :missing) == nil
  end

  test "finds deepest layout node at coordinates" do
    node =
      box padding: 1 do
        input(id: :name, value: "Dan")
      end
      |> Engine.layout()

    assert Layout.at(node, 2, 2).id == :name
    assert Layout.at(node, 0, 0).id == nil
    assert Layout.at(node, 200, 200) == nil
  end

  test "returns node paths at coordinates" do
    node =
      box id: :shell, padding: 1 do
        input(id: :name, value: "Dan")
      end
      |> Engine.layout()

    assert [:shell, :name] = node |> Layout.path_at(2, 2) |> Enum.map(& &1.id)
    assert [] = Layout.path_at(node, 200, 200)
  end

  test "lists focusable layout nodes" do
    node =
      column gap: 1 do
        input(id: :name, value: "Dan")
        select(id: :role, options: ["Admin", "User"])
        text("not focusable", id: :label)
      end
      |> Engine.layout()

    assert [:name, :role] = node |> Layout.focusable() |> Enum.map(& &1.id)
    assert Layout.find(node, :name).role == :input
    assert Layout.find(node, :role).role == :select
  end

  test "moves focus through focusable nodes" do
    node =
      column gap: 1 do
        input(id: :name, value: "Dan")
        input(id: :email, value: "dan@example.com")
        select(id: :role, options: ["Admin", "User"])
      end
      |> Engine.layout()

    assert Layout.focus_id(node, :next) == :name
    assert Layout.focus_id(node, :next, :name) == :email
    assert Layout.focus_id(node, :next, :role) == :name
    assert Layout.focus_id(node, :previous) == :role
    assert Layout.focus_id(node, :previous, :name) == :role
    assert Layout.next_focus(node, :email).id == :role
    assert Layout.previous_focus(node, :email).id == :name
  end
end
