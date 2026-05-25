defmodule Cringe.Layout.Engine do
  @moduledoc """
  Lays out document trees into positioned layout nodes.
  """

  alias Cringe.ANSI
  alias Cringe.Document.{Box, Stack, Text}
  alias Cringe.Layout
  alias Cringe.Layout.{Constraint, Node}
  alias Cringe.Measure

  @spec layout(Cringe.Document.t(), keyword()) :: Node.t()
  def layout(document, opts \\ []) do
    constraint = Constraint.new(opts)
    ansi? = Keyword.get(opts, :ansi, false)

    document
    |> layout_node(ansi?)
    |> apply_root_constraint(constraint)
  end

  defp layout_node(%Text{content: content, opts: opts} = document, ansi?) do
    lines =
      content
      |> String.split("\n", trim: false)
      |> Enum.map(&ANSI.apply(&1, opts, ansi?))
      |> Layout.resize_block(opts)

    Node.new(document, lines)
  end

  defp layout_node(%Stack{direction: :vertical, children: children, opts: opts} = document, ansi?) do
    gap = Keyword.get(opts, :gap, 0)
    separator = List.duplicate("", gap)
    child_nodes = children |> Enum.map(&layout_node(&1, ansi?)) |> position_vertical(gap)

    lines =
      child_nodes
      |> Enum.map(& &1.lines)
      |> Enum.reject(&(&1 == []))
      |> join_blocks(separator)
      |> Layout.resize_block(opts)

    Node.new(document, lines, children: child_nodes)
  end

  defp layout_node(
         %Stack{direction: :horizontal, children: children, opts: opts} = document,
         ansi?
       ) do
    gap = Keyword.get(opts, :gap, 0)
    separator = String.duplicate(" ", gap)
    child_nodes = Enum.map(children, &layout_node(&1, ansi?))
    blocks = Enum.map(child_nodes, & &1.lines)
    widths = row_widths(children, blocks, gap, Keyword.get(opts, :width))
    height = blocks |> Enum.map(&length/1) |> Enum.max(fn -> 0 end)

    resized_blocks =
      blocks
      |> Enum.zip(widths)
      |> Enum.map(fn {block, width} ->
        block |> pad_block_height(height) |> Layout.resize_width(width, :left)
      end)

    lines =
      resized_blocks
      |> transpose_blocks()
      |> join_rows(separator)
      |> Layout.resize_block(Keyword.drop(opts, [:width]))

    children = position_horizontal(child_nodes, widths, gap)
    Node.new(document, lines, children: children)
  end

  defp layout_node(%Box{child: child, opts: opts} = document, ansi?) do
    padding = Keyword.get(opts, :padding, 0)
    border = Keyword.get(opts, :border, :rounded)
    child_node = layout_node(child, ansi?)
    content = pad_block(child_node.lines, padding)

    lines =
      case border do
        false -> content
        nil -> content
        _ -> bordered(content, border)
      end
      |> Layout.resize_block(opts)

    Node.new(document, lines, children: [position_box_child(child_node, padding, border)])
  end

  defp apply_root_constraint(node, %Constraint{} = constraint) do
    lines =
      node.lines
      |> maybe_clip_height(constraint.height)
      |> Enum.map(&maybe_clip_width(&1, constraint.width))

    Node.new(node.document, lines, children: node.children)
  end

  defp position_vertical(nodes, gap) do
    nodes
    |> Enum.map_reduce(0, fn node, y ->
      {%{node | rect: %{node.rect | y: y}}, y + node.rect.height + gap}
    end)
    |> elem(0)
  end

  defp position_horizontal(nodes, widths, gap) do
    nodes
    |> Enum.zip(widths)
    |> Enum.map_reduce(0, fn {node, width}, x ->
      {%{node | rect: %{node.rect | x: x, width: width}}, x + width + gap}
    end)
    |> elem(0)
  end

  defp position_box_child(node, padding, border) do
    offset = padding + border_offset(border)
    %{node | rect: %{node.rect | x: offset, y: offset}}
  end

  defp border_offset(false), do: 0
  defp border_offset(nil), do: 0
  defp border_offset(_border), do: 1

  defp join_blocks([], _separator), do: []

  defp join_blocks(blocks, separator) do
    blocks
    |> Enum.intersperse(separator)
    |> List.flatten()
  end

  defp row_widths(children, blocks, gap, target_width) do
    natural = Enum.map(blocks, &block_width/1)
    requested = Enum.map(children, &requested_width/1)
    grow = Enum.map(children, &grow/1)
    base = Enum.zip_with(requested, natural, &(&1 || &2))

    distribute_grow(base, grow, target_width, gap)
  end

  defp requested_width(%{opts: opts}), do: Keyword.get(opts, :width)
  defp grow(%{opts: opts}), do: Keyword.get(opts, :grow, 0)

  defp distribute_grow(base, _grow, nil, _gap), do: base

  defp distribute_grow(base, grow, target_width, gap) do
    total_gap = max(length(base) - 1, 0) * gap
    extra = max(target_width - Enum.sum(base) - total_gap, 0)
    total_grow = Enum.sum(grow)

    if total_grow > 0 do
      distribute_extra(base, grow, extra, total_grow)
    else
      base
    end
  end

  defp distribute_extra(base, grow, extra, total_grow) do
    shares = Enum.map(grow, &div(extra * &1, total_grow))
    used = Enum.sum(shares)
    remainder = extra - used

    base
    |> Enum.zip(shares)
    |> Enum.with_index()
    |> Enum.map(fn {{width, share}, index} ->
      width + share + if(index < remainder, do: 1, else: 0)
    end)
  end

  defp pad_block_height(block, height) do
    block ++ List.duplicate("", max(height - length(block), 0))
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
