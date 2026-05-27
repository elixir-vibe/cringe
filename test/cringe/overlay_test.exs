defmodule Cringe.OverlayTest do
  use ExUnit.Case, async: true

  use Cringe.Case

  alias Cringe.Overlay
  alias Cringe.Overlay.Layer
  alias Cringe.Overlay.State

  test "composes centered overlays over base documents" do
    overlays = Overlay.new([Overlay.layer(:dialog, Cringe.text("OK"), anchor: :center)])

    assert Overlay.render(Cringe.text("base"), overlays, width: 8, height: 3) ==
             "base    \n   OK   \n        "
  end

  test "positions overlays by anchor and margin" do
    overlays =
      Overlay.new([Overlay.layer(:note, Cringe.text("!"), anchor: :bottom_right, margin: 1)])

    assert Overlay.render(Cringe.text("base"), overlays, width: 6, height: 3) ==
             "base  \n    ! \n      "
  end

  test "explicit coordinates override anchors" do
    overlays =
      Overlay.new([Overlay.layer(:note, Cringe.text("!"), x: 1, y: 1, anchor: :bottom_right)])

    assert Overlay.render(Cringe.text("base"), overlays, width: 6, height: 3) ==
             "base  \n !    \n      "
  end

  test "later layers render above earlier layers" do
    overlays =
      Overlay.new([
        Overlay.layer(:first, Cringe.text("A"), x: 1, y: 0),
        Overlay.layer(:second, Cringe.text("B"), x: 1, y: 0)
      ])

    assert Overlay.render(Cringe.text("base"), overlays, width: 5, height: 1) == "bBse "
  end

  test "state replaces and removes layers by id" do
    state =
      Overlay.new()
      |> Overlay.put(Overlay.layer(:one, Cringe.text("one")))
      |> Overlay.put(Overlay.layer(:one, Cringe.text("two")))

    assert [%Layer{id: :one, document: document}] = state.layers
    assert render(document) == "two"
    assert Overlay.remove(state, :one) == %State{layers: []}
  end

  test "returns topmost capturing layer" do
    state =
      Overlay.new([
        Overlay.layer(:base_hint, Cringe.text("hint"), capture?: false),
        Overlay.layer(:dialog, Cringe.text("dialog"), capture?: true)
      ])

    assert State.top(state).id == :dialog
    assert State.capturing(state).id == :dialog
  end

  test "translates overlay cursors" do
    overlays =
      Overlay.new([Overlay.layer(:input, Cringe.input(value: "a", focused: true), x: 2, y: 1)])

    assert Overlay.frame(Cringe.text("base"), overlays, width: 12, height: 3).cursor == {2, 6}
  end
end
