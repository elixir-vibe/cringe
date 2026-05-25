defmodule Cringe.Layout do
  @moduledoc false

  alias Cringe.Measure

  @spec block_width([String.t()]) :: non_neg_integer()
  def block_width(lines) do
    lines
    |> Enum.map(&Measure.width/1)
    |> Enum.max(fn -> 0 end)
  end

  @spec resize_block([String.t()], keyword()) :: [String.t()]
  def resize_block(lines, opts) do
    width = constrained_width(lines, opts)
    height = Keyword.get(opts, :height)
    align = Keyword.get(opts, :align, :left)

    lines
    |> maybe_resize_width(width, align)
    |> maybe_resize_height(height)
  end

  @spec resize_width([String.t()], non_neg_integer(), atom()) :: [String.t()]
  def resize_width(lines, width, align \\ :left) when is_integer(width) and width >= 0 do
    Enum.map(lines, &resize_line(&1, width, align))
  end

  @spec resize_line(String.t(), non_neg_integer(), atom()) :: String.t()
  def resize_line(line, width, align \\ :left)
      when is_binary(line) and is_integer(width) and width >= 0 do
    line_width = Measure.width(line)

    cond do
      line_width > width ->
        Measure.take(line, width)

      line_width == width ->
        line

      true ->
        pad_aligned(line, width - line_width, align)
    end
  end

  defp constrained_width(lines, opts) do
    if Keyword.has_key?(opts, :width) or Keyword.has_key?(opts, :min_width) or
         Keyword.has_key?(opts, :max_width) do
      natural = block_width(lines)

      opts
      |> Keyword.get(:width, natural)
      |> max(Keyword.get(opts, :min_width, 0))
      |> cap_width(Keyword.get(opts, :max_width, :infinity))
    end
  end

  defp maybe_resize_width(lines, nil, _align), do: lines
  defp maybe_resize_width(lines, width, align), do: resize_width(lines, width, align)

  defp maybe_resize_height(lines, nil), do: lines

  defp maybe_resize_height(lines, height) when is_integer(height) and height >= 0 do
    lines
    |> Enum.take(height)
    |> pad_height(height)
  end

  defp pad_height(lines, height) do
    width = block_width(lines)
    lines ++ List.duplicate(String.duplicate(" ", width), max(height - length(lines), 0))
  end

  defp cap_width(width, :infinity), do: width
  defp cap_width(width, max_width), do: min(width, max_width)

  defp pad_aligned(line, padding, :right), do: String.duplicate(" ", padding) <> line

  defp pad_aligned(line, padding, :center) do
    left = div(padding, 2)
    right = padding - left
    String.duplicate(" ", left) <> line <> String.duplicate(" ", right)
  end

  defp pad_aligned(line, padding, _align), do: line <> String.duplicate(" ", padding)
end
