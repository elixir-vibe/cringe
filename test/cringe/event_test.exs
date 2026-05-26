defmodule Cringe.EventTest do
  use ExUnit.Case, async: true

  test "builds semantic events" do
    assert Cringe.Event.key(:enter, mods: [:ctrl]) == %Cringe.Event.Key{
             key: :enter,
             mods: [:ctrl]
           }

    assert Cringe.Event.text("a") == %Cringe.Event.Text{text: "a"}
    assert Cringe.Event.resize(120, 40) == %Cringe.Event.Resize{width: 120, height: 40}
    assert Cringe.Event.tick(:spinner) == %Cringe.Event.Tick{id: :spinner}
  end
end
