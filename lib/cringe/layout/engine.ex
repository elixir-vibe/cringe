defmodule Cringe.Layout.Engine do
  @moduledoc """
  Lays out document trees into positioned layout nodes.
  """

  alias Cringe.Document.{Box, Stack, Text}
  alias Cringe.Layout
  alias Cringe.Layout.{Constraint, Node, Size}
  alias Cringe.Measure
  alias Cringe.Rect

  @spec layout(Cringe.Document.t(), keyword()) :: Node.t()
  def layout(document, opts \\ []) do
    constraint = Constraint.new(opts)

    document
    |> layout_node()
    |> apply_root_constraint(constraint)
  end

  defp layout_node(%Text{content: content, opts: opts} = document) do
    lines =
      content
      |> String.split("\n", trim: false)
      |> Layout.resize_block(opts)

    Node.new(document, lines, cursor: Keyword.get(opts, :cursor), text_lines: lines)
  end

  defp layout_node(%Stack{direction: :vertical, children: children, opts: opts} = document) do
    gap = Keyword.get(opts, :gap, 0)
    child_nodes = children |> Enum.map(&layout_node/1) |> position_vertical(gap)
    size = child_nodes |> vertical_stack_size(gap) |> constrain_size(opts)

    Node.new_sized(document, size,
      children: child_nodes,
      cursor: first_cursor(child_nodes)
    )
  end

  defp layout_node(%Stack{direction: :horizontal, children: children, opts: opts} = document) do
    gap = Keyword.get(opts, :gap, 0)
    child_nodes = Enum.map(children, &layout_node/1)
    widths = row_widths(children, child_nodes, gap, Keyword.get(opts, :width))
    positioned_children = position_horizontal(child_nodes, widths, gap)

    size =
      positioned_children
      |> horizontal_stack_size(gap)
      |> constrain_size(Keyword.drop(opts, [:width]))

    Node.new_sized(document, size,
      children: positioned_children,
      cursor: first_cursor(positioned_children)
    )
  end

  defp layout_node(%Box{child: child, opts: opts} = document) do
    padding = Keyword.get(opts, :padding, 0)
    border = Keyword.get(opts, :border, :rounded)
    child_node = layout_node(child)
    offset = padding + border_offset(border)
    scroll_y = Keyword.get(opts, :scroll_y, 0)

    natural_content_size = visible_box_content_size(child_node, opts, offset)

    natural_size =
      Size.new(natural_content_size.width + offset * 2, natural_content_size.height + offset * 2)

    size = constrain_size(natural_size, opts)
    child_node = position_box_child(child_node, offset)

    content_rect =
      Rect.new(offset, offset, max(size.width - offset * 2, 0), max(size.height - offset * 2, 0))

    Node.new_sized(document, size,
      children: [child_node],
      content_rect: content_rect,
      cursor: box_cursor(child_node.cursor, child_node.rect, scroll_y, content_rect)
    )
  end

  defp apply_root_constraint(%Node{document: %Text{}} = node, %Constraint{} = constraint) do
    lines =
      node.lines
      |> maybe_clip_height(constraint.height)
      |> Enum.map(&maybe_clip_width(&1, constraint.width))

    size = Size.new(block_width(lines), length(lines))
    Node.new(node.document, lines, cursor: clip_cursor(node.cursor, size), text_lines: lines)
  end

  defp apply_root_constraint(node, %Constraint{} = constraint) do
    size =
      Size.new(
        maybe_constrain_dimension(node.rect.width, constraint.width),
        maybe_constrain_dimension(node.rect.height, constraint.height)
      )

    Node.new_sized(node.document, size,
      children: node.children,
      content_rect: clip_rect(node.content_rect, size),
      cursor: clip_cursor(node.cursor, size)
    )
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

  defp position_box_child(node, offset) do
    %{node | rect: %{node.rect | x: offset, y: offset}}
  end

  defp first_cursor(nodes) do
    Enum.find_value(nodes, &translate_cursor(&1.cursor, &1.rect))
  end

  defp translate_cursor(nil, _rect), do: nil
  defp translate_cursor({row, col}, rect), do: {row + rect.y, col + rect.x}

  defp clip_rect(rect, size) do
    Rect.new(rect.x, rect.y, min(rect.width, size.width), min(rect.height, size.height))
  end

  defp clip_cursor(nil, _size), do: nil

  defp clip_cursor({row, col} = cursor, %Size{} = size) do
    if row <= size.height and col <= size.width + 1 do
      cursor
    end
  end

  defp border_offset(false), do: 0
  defp border_offset(nil), do: 0
  defp border_offset(_border), do: 1

  defp visible_box_content_size(child_node, opts, offset) do
    if Keyword.get(opts, :overflow) == :hidden and Keyword.has_key?(opts, :height) do
      height = max(Keyword.fetch!(opts, :height) - offset * 2, 0)

      lines =
        child_node.lines
        |> maybe_scroll(Keyword.get(opts, :scroll_y, 0))
        |> Enum.take(height)

      Size.new(block_width(lines), length(lines))
    else
      Size.new(child_node.rect.width, child_node.rect.height)
    end
  end

  defp maybe_scroll(lines, scroll_y) when is_integer(scroll_y) and scroll_y > 0,
    do: Enum.drop(lines, scroll_y)

  defp maybe_scroll(lines, _scroll_y), do: lines

  defp box_cursor(nil, _rect, _scroll_y, _content_rect), do: nil

  defp box_cursor({row, col}, rect, scroll_y, content_rect) do
    cursor = {row + rect.y - scroll_y, col + rect.x}

    if in_rect?(cursor, content_rect) do
      cursor
    end
  end

  defp in_rect?({row, col}, rect) do
    row > rect.y and row <= rect.y + rect.height and col > rect.x and
      col <= rect.x + rect.width + 1
  end

  defp vertical_stack_size([], _gap), do: Size.new(0, 0)

  defp vertical_stack_size(nodes, gap) do
    width = nodes |> Enum.map(& &1.rect.width) |> Enum.max(fn -> 0 end)
    height = Enum.reduce(nodes, 0, &(&2 + &1.rect.height)) + max(length(nodes) - 1, 0) * gap
    Size.new(width, height)
  end

  defp horizontal_stack_size([], _gap), do: Size.new(0, 0)

  defp horizontal_stack_size(nodes, gap) do
    width = Enum.reduce(nodes, 0, &(&2 + &1.rect.width)) + max(length(nodes) - 1, 0) * gap
    height = nodes |> Enum.map(& &1.rect.height) |> Enum.max(fn -> 0 end)
    Size.new(width, height)
  end

  defp row_widths(children, nodes, gap, target_width) do
    natural = Enum.map(nodes, & &1.rect.width)
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

  defp constrain_size(%Size{} = size, opts) do
    lines = Layout.resize_block(blank_lines(size), opts)
    Size.new(block_width(lines), length(lines))
  end

  defp maybe_constrain_dimension(value, nil), do: value

  defp maybe_constrain_dimension(_value, dimension) when is_integer(dimension) and dimension >= 0,
    do: dimension

  defp maybe_clip_height(lines, nil), do: lines

  defp maybe_clip_height(lines, height) when is_integer(height) and height >= 0,
    do: Enum.take(lines, height)

  defp maybe_clip_width(line, nil), do: line

  defp maybe_clip_width(line, width) when is_integer(width) and width >= 0,
    do: Measure.take(line, width)

  defp blank_lines(%Size{width: width, height: height}) do
    blank = String.duplicate(" ", width)
    List.duplicate(blank, height)
  end

  defp block_width(lines) do
    lines
    |> Enum.map(&Measure.width/1)
    |> Enum.max(fn -> 0 end)
  end
end
