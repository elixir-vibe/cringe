defmodule Cringe.Measure do
  @moduledoc false

  @variation_selector_16 0xFE0F
  @zero_width_joiner 0x200D
  @zero_width_ranges [
    0x0300..0x036F,
    0x1AB0..0x1AFF,
    0x1DC0..0x1DFF,
    0x20D0..0x20FF,
    0xFE00..0xFE0F
  ]
  @wide_ranges [
    0x1100..0x115F,
    0x2329..0x232A,
    0x2E80..0xA4CF,
    0xAC00..0xD7A3,
    0xF900..0xFAFF,
    0xFE10..0xFE19,
    0xFE30..0xFE6F,
    0xFF00..0xFF60,
    0xFFE0..0xFFE6,
    0x1F000..0x1FAFF,
    0x2600..0x27BF
  ]

  @spec width(String.t()) :: non_neg_integer()
  def width(text) when is_binary(text) do
    text
    |> Cringe.ANSI.strip()
    |> String.graphemes()
    |> Enum.reduce(0, &(&2 + grapheme_width(&1)))
  end

  @spec take(String.t(), non_neg_integer()) :: String.t()
  def take(text, width) when is_binary(text) and is_integer(width) and width >= 0 do
    {result, _visible, active_sgr} = take_ansi(text, width, 0, "", [])
    result <> reset_if_styled(active_sgr)
  end

  @spec pad(String.t(), non_neg_integer()) :: String.t()
  def pad(text, width) when is_binary(text) and is_integer(width) do
    text <> String.duplicate(" ", max(width - width(text), 0))
  end

  @spec fit(String.t(), non_neg_integer(), keyword()) :: String.t()
  def fit(text, width, opts \\ []) when is_binary(text) and is_integer(width) and width >= 0 do
    cond do
      width(text) <= width ->
        pad(text, width)

      Keyword.get(opts, :ellipsis?, false) and width > 0 ->
        take(text, width - 1) <> "…"

      true ->
        take(text, width)
    end
  end

  @spec drop(String.t(), non_neg_integer()) :: String.t()
  def drop(text, count) when is_binary(text) and is_integer(count) and count >= 0 do
    text
    |> Cringe.ANSI.strip()
    |> do_drop(count, 0, [])
  end

  defp take_ansi(_text, width, visible, acc, active_sgr) when visible >= width do
    {acc, visible, active_sgr}
  end

  defp take_ansi("", _width, visible, acc, active_sgr), do: {acc, visible, active_sgr}

  defp take_ansi(<<"\e[", rest::binary>>, width, visible, acc, active_sgr) do
    {escape, rest} = take_escape(rest, "\e[")
    take_ansi(rest, width, visible, acc <> escape, update_sgr(active_sgr, escape))
  end

  defp take_ansi(text, width, visible, acc, active_sgr) do
    case String.next_grapheme(text) do
      {grapheme, rest} ->
        grapheme_width = grapheme_width(grapheme)

        if visible + grapheme_width <= width do
          take_ansi(rest, width, visible + grapheme_width, acc <> grapheme, active_sgr)
        else
          {acc, visible, active_sgr}
        end

      nil ->
        {acc, visible, active_sgr}
    end
  end

  defp take_escape(<<"m", rest::binary>>, acc), do: {acc <> "m", rest}

  defp take_escape(<<char::binary-size(1), rest::binary>>, acc),
    do: take_escape(rest, acc <> char)

  defp take_escape("", acc), do: {acc, ""}

  defp update_sgr(_active_sgr, "\e[0m"), do: []
  defp update_sgr(_active_sgr, "\e[m"), do: []
  defp update_sgr(active_sgr, "\e[" <> _params = escape), do: [escape | active_sgr]
  defp update_sgr(active_sgr, _escape), do: active_sgr

  defp reset_if_styled([]), do: ""
  defp reset_if_styled(_active_sgr), do: "\e[0m"

  defp do_drop(text, count, visible, acc) when visible >= count,
    do: Enum.reverse(acc) |> Enum.join() |> Kernel.<>(text)

  defp do_drop("", _count, _visible, acc), do: Enum.reverse(acc) |> Enum.join()

  defp do_drop(text, count, visible, acc) do
    case String.next_grapheme(text) do
      {grapheme, rest} ->
        do_drop(rest, count, visible + grapheme_width(grapheme), acc)

      nil ->
        Enum.reverse(acc) |> Enum.join()
    end
  end

  defp grapheme_width(grapheme) do
    grapheme
    |> String.to_charlist()
    |> width_properties()
    |> width_from_properties()
  end

  defp width_properties(codepoints) do
    Enum.reduce(
      codepoints,
      %{any?: false, joiner?: false, variation?: false, wide?: false, all_zero?: true},
      fn codepoint, acc ->
        %{
          any?: true,
          joiner?: acc.joiner? or codepoint == @zero_width_joiner,
          variation?: acc.variation? or codepoint == @variation_selector_16,
          wide?: acc.wide? or wide_codepoint?(codepoint),
          all_zero?: acc.all_zero? and zero_width_codepoint?(codepoint)
        }
      end
    )
  end

  defp width_from_properties(%{any?: false}), do: 0
  defp width_from_properties(%{joiner?: true}), do: 2
  defp width_from_properties(%{variation?: true}), do: 2
  defp width_from_properties(%{wide?: true}), do: 2
  defp width_from_properties(%{all_zero?: true}), do: 0
  defp width_from_properties(_properties), do: 1

  defp zero_width_codepoint?(codepoint), do: in_any_range?(codepoint, @zero_width_ranges)
  defp wide_codepoint?(codepoint), do: in_any_range?(codepoint, @wide_ranges)
  defp in_any_range?(codepoint, ranges), do: Enum.any?(ranges, &(codepoint in &1))
end
