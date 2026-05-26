defmodule Cringe.Terminal.KeyDecoderTest do
  use ExUnit.Case, async: true

  alias Cringe.Terminal.KeyDecoder

  test "decodes common key sequences through Ghostty" do
    assert KeyDecoder.decode("\e[A") == [Cringe.Event.key(:up)]
    assert KeyDecoder.decode("\e[B") == [Cringe.Event.key(:down)]
    assert KeyDecoder.decode("\r") == [Cringe.Event.key(:enter)]
    assert KeyDecoder.decode("\u007F") == [Cringe.Event.key(:backspace)]
  end

  test "decodes printable text through Ghostty" do
    assert KeyDecoder.decode("a") == [Cringe.Event.text("a")]
  end

  test "decodes ctrl+c through Ghostty" do
    assert KeyDecoder.decode("\u0003") == [Cringe.Event.key(:c, mods: [:ctrl])]
  end

  test "maps Ghostty key events to Cringe events" do
    event = %Ghostty.KeyEvent{action: :press, key: :arrow_left, mods: [:super]}

    assert KeyDecoder.from_ghostty(event) == Cringe.Event.key(:left, mods: [:meta])
  end
end
