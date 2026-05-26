defmodule Cringe.Terminal.KeyDecoder do
  @moduledoc """
  Small terminal key decoder for common ANSI input sequences.
  """

  @spec decode(binary()) :: [Cringe.Event.t()]
  def decode(input) when is_binary(input) do
    input
    |> do_decode([])
    |> Enum.reverse()
  end

  defp do_decode("", events), do: events
  defp do_decode("\e[A" <> rest, events), do: do_decode(rest, [Cringe.Event.key(:up) | events])
  defp do_decode("\e[B" <> rest, events), do: do_decode(rest, [Cringe.Event.key(:down) | events])
  defp do_decode("\e[C" <> rest, events), do: do_decode(rest, [Cringe.Event.key(:right) | events])
  defp do_decode("\e[D" <> rest, events), do: do_decode(rest, [Cringe.Event.key(:left) | events])
  defp do_decode("\r" <> rest, events), do: do_decode(rest, [Cringe.Event.key(:enter) | events])
  defp do_decode("\n" <> rest, events), do: do_decode(rest, [Cringe.Event.key(:enter) | events])
  defp do_decode("\e" <> rest, events), do: do_decode(rest, [Cringe.Event.key(:escape) | events])

  defp do_decode("\u007F" <> rest, events),
    do: do_decode(rest, [Cringe.Event.key(:backspace) | events])

  defp do_decode("\b" <> rest, events),
    do: do_decode(rest, [Cringe.Event.key(:backspace) | events])

  defp do_decode("\u0003" <> rest, events),
    do: do_decode(rest, [Cringe.Event.key(:c, mods: [:ctrl]) | events])

  defp do_decode(<<char::utf8, rest::binary>>, events) do
    do_decode(rest, [Cringe.Event.text(<<char::utf8>>) | events])
  end
end
