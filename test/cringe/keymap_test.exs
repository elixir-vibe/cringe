defmodule Cringe.KeymapTest do
  use ExUnit.Case, async: true

  alias Cringe.Keymap
  alias Cringe.Keymap.Binding

  test "matches key events by action" do
    keymap = Keymap.new(cancel: [:escape, {:c, [:ctrl]}])

    assert Keymap.match?(keymap, :cancel, Cringe.Event.key(:escape))
    assert Keymap.match?(keymap, :cancel, Cringe.Event.key(:c, mods: [:ctrl]))
    refute Keymap.match?(keymap, :cancel, Cringe.Event.key(:c))
  end

  test "resolves the first action for an event" do
    keymap = Keymap.new(confirm: [:enter], cancel: [:escape])

    assert Keymap.action(keymap, Cringe.Event.key(:enter)) == {:ok, :confirm}
    assert Keymap.action(keymap, Cringe.Event.key(:tab)) == :error
  end

  test "stores bindings as structs" do
    keymap = Keymap.new(next: [Binding.new(:down), :j])

    assert Keymap.bindings(keymap, :next) == [
             %Binding{key: :down, mods: []},
             %Binding{key: :j, mods: []}
           ]
  end

  test "compares modifiers independent of order" do
    binding = Binding.new(:enter, mods: [:shift, :ctrl])

    assert Binding.matches?(binding, Cringe.Event.key(:enter, mods: [:ctrl, :shift]))
  end
end
