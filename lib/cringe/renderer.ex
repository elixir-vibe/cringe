defmodule Cringe.Renderer do
  @moduledoc """
  Renders Cringe documents into terminal text.
  """

  alias Cringe.Document.{Box, Stack, Text}
  alias Cringe.Measure

  @type render_opts :: [width: pos_integer(), height: pos_integer()]

  @spec render(Cringe.Document.t(), render_opts()) :: String.t()
  def render(document, opts \\ []) do
    width = Keyword.get(opts, :width)
    height = Keyword.get(opts, :height)

    document
    |> lines()
    |> maybe_clip_height(height)
    |> Enum.map_join("\n", &maybe_clip_width(&1, width))
  end

  defp lines(%Text{content: content}) do
    String.split(content, "\n", trim: false)
  end

  defp lines(%Stack{direction: :vertical, children: children, opts: opts}) do
    gap = Keyword.get(opts, :gap, 0)
    separator = List.duplicate("", gap)

    children
    |> Enum.map(&lines/1)
    |> Enum.reject(&(&1 == []))
    |> join_blocks(separator)
  end

  defp lines(%Stack{direction: :horizontal, children: children, opts: opts}) do
    gap = Keyword.get(opts, :gap, 0)
    separator = String.duplicate(" ", gap)
    blocks = Enum.map(children, &lines/1)
    height = blocks |> Enum.map(&length/1) |> Enum.max(fn -> 0 end)

    blocks
    |> Enum.map(&pad_block_height(&1, height))
    |> Enum.map(&pad_block_width/1)
    |> transpose_blocks()
    |> join_rows(separator)
  end

  defp lines(%Box{child: child, opts: opts}) do
    padding = Keyword.get(opts, :padding, 0)
    border = Keyword.get(opts, :border, :rounded)
    content = child |> lines() |> pad_block(padding)

    case border do
      false -> content
      nil -> content
      _ -> bordered(content, border)
    end
  end

  defp join_blocks([], _separator), do: []

  defp join_blocks(blocks, separator) do
    blocks
    |> Enum.intersperse(separator)
    |> List.flatten()
  end

  defp pad_block_height(block, height) do
    block ++ List.duplicate("", max(height - length(block), 0))
  end

  defp pad_block_width(block) do
    width = block_width(block)
    Enum.map(block, &Measure.pad(&1, width))
  end

  defp transpose_blocks([]), do: []

  defp transpose_blocks(blocks) do
    blocks
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
  end

  defp join_rows(rows, separator), do: Enum.map(rows, &Enum.join(&1, separator))

  defp block_width(lines) do
    lines
    |> Enum.map(&Measure.width/1)
    |> Enum.max(fn -> 0 end)
  end

  defp pad_block(lines, 0), do: lines

  defp pad_block(lines, padding) when is_integer(padding) and padding > 0 do
    width = block_width(lines)
    side = String.duplicate(" ", padding)
    blank = String.duplicate(" ", width + padding * 2)

    vertical = List.duplicate(blank, padding)
    padded = Enum.map(lines, &([side, Measure.pad(&1, width), side] |> IO.iodata_to_binary()))

    vertical ++ padded ++ vertical
  end

  defp bordered(lines, border) do
    width = block_width(lines)
    {top_left, top_right, bottom_left, bottom_right, horizontal, vertical} = border_chars(border)
    horizontal_rule = String.duplicate(horizontal, width)

    top = top_left <> horizontal_rule <> top_right
    bottom = bottom_left <> horizontal_rule <> bottom_right
    body = Enum.map(lines, &(vertical <> Measure.pad(&1, width) <> vertical))

    [top | body] ++ [bottom]
  end

  defp border_chars(:square), do: {"+", "+", "+", "+", "-", "|"}
  defp border_chars(_border), do: {"╭", "╮", "╰", "╯", "─", "│"}

  defp maybe_clip_height(lines, nil), do: lines

  defp maybe_clip_height(lines, height) when is_integer(height) and height > 0,
    do: Enum.take(lines, height)

  defp maybe_clip_width(line, nil), do: line

  defp maybe_clip_width(line, width) when is_integer(width) and width > 0,
    do: Measure.take(line, width)
end
