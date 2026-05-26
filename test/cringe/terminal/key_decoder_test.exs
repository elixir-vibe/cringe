defmodule Cringe.Terminal.KeyDecoderTest do
  use ExUnit.Case, async: true

  alias Cringe.Terminal.KeyDecoder

  test "decodes common key sequences" do
    assert KeyDecoder.decode("\e[A\e[B\r\u007F") == [
             Cringe.Event.key(:up),
             Cringe.Event.key(:down),
             Cringe.Event.key(:enter),
             Cringe.Event.key(:backspace)
           ]
  end

  test "decodes printable text" do
    assert KeyDecoder.decode("ab") == [Cringe.Event.text("a"), Cringe.Event.text("b")]
  end

  test "decodes ctrl+c" do
    assert KeyDecoder.decode("\u0003") == [Cringe.Event.key(:c, mods: [:ctrl])]
  end
end
