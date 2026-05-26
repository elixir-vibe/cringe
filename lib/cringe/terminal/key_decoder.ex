defmodule Cringe.Terminal.KeyDecoder do
  @moduledoc """
  Adapts Ghostty terminal key decoding into Cringe events.
  """

  alias Ghostty.KeyEvent

  @spec decode(binary()) :: [Cringe.Event.t()]
  def decode(input) when is_binary(input) do
    input
    |> Ghostty.KeyDecoder.decode()
    |> to_events()
  end

  @spec from_ghostty(KeyEvent.t()) :: Cringe.Event.t() | :ignore
  def from_ghostty(%KeyEvent{action: action}) when action != :press, do: :ignore

  def from_ghostty(%KeyEvent{utf8: utf8, mods: []}) when is_binary(utf8) and utf8 != "" do
    Cringe.Event.text(utf8)
  end

  def from_ghostty(%KeyEvent{key: key, mods: mods}) do
    Cringe.Event.key(normalize_key(key), mods: normalize_mods(mods))
  end

  defp to_events({:key, %KeyEvent{} = event}) do
    case from_ghostty(event) do
      :ignore -> []
      event -> [event]
    end
  end

  defp to_events({:data, data}) when is_binary(data), do: [Cringe.Event.text(data)]

  defp normalize_key(:arrow_up), do: :up
  defp normalize_key(:arrow_down), do: :down
  defp normalize_key(:arrow_left), do: :left
  defp normalize_key(:arrow_right), do: :right
  defp normalize_key(:digit_0), do: :zero
  defp normalize_key(:digit_1), do: :one
  defp normalize_key(:digit_2), do: :two
  defp normalize_key(:digit_3), do: :three
  defp normalize_key(:digit_4), do: :four
  defp normalize_key(:digit_5), do: :five
  defp normalize_key(:digit_6), do: :six
  defp normalize_key(:digit_7), do: :seven
  defp normalize_key(:digit_8), do: :eight
  defp normalize_key(:digit_9), do: :nine
  defp normalize_key(key), do: key

  defp normalize_mods(mods), do: Enum.map(mods, &normalize_mod/1)

  defp normalize_mod(:super), do: :meta
  defp normalize_mod(mod), do: mod
end
