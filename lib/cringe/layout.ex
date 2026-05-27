defmodule Cringe.Layout do
  @moduledoc """
  Layout query and sizing helpers.

  `Cringe.Layout.Engine.layout/2` turns a document into a positioned tree of
  `Cringe.Layout.Node` structs. This module provides small helpers for querying
  that tree by document IDs, coordinates, and focus metadata.
  """

  alias Cringe.Layout.Node
  alias Cringe.Measure

  @doc """
  Returns the maximum terminal-cell width of a block of lines.
  """
  @spec block_width([String.t()]) :: non_neg_integer()
  def block_width(lines) do
    lines
    |> Enum.map(&Measure.width/1)
    |> Enum.max(fn -> 0 end)
  end

  @doc """
  Finds the first layout node with the given document ID.
  """
  @spec find(Node.t(), term()) :: Node.t() | nil
  def find(%Node{id: id} = node, id), do: node
  def find(%Node{children: children}, id), do: Enum.find_value(children, &find(&1, id))

  @doc """
  Finds the deepest node containing zero-based coordinates relative to `node`.
  """
  @spec at(Node.t(), non_neg_integer(), non_neg_integer()) :: Node.t() | nil
  def at(%Node{} = node, x, y) when is_integer(x) and is_integer(y) do
    if contains?(node.rect, x, y) do
      Enum.find_value(node.children, &at(&1, x - node.rect.x, y - node.rect.y)) || node
    end
  end

  @doc """
  Returns the path from `node` to the deepest node containing coordinates.
  """
  @spec path_at(Node.t(), non_neg_integer(), non_neg_integer()) :: [Node.t()]
  def path_at(%Node{} = node, x, y) when is_integer(x) and is_integer(y) do
    if contains?(node.rect, x, y) do
      child_path = Enum.find_value(node.children, &path_at(&1, x - node.rect.x, y - node.rect.y))
      [node | child_path || []]
    else
      []
    end
  end

  @doc """
  Lists focusable nodes in layout order.
  """
  @spec focusable(Node.t()) :: [Node.t()]
  def focusable(%Node{} = node) do
    descendants = Enum.flat_map(node.children, &focusable/1)

    if node.focusable? do
      [node | descendants]
    else
      descendants
    end
  end

  @doc """
  Returns the next focusable node after `current_id`, wrapping at the end.
  """
  @spec next_focus(Node.t(), term() | nil) :: Node.t() | nil
  def next_focus(%Node{} = node, current_id \\ nil) do
    move_focus(node, current_id, 1)
  end

  @doc """
  Returns the previous focusable node before `current_id`, wrapping at the start.
  """
  @spec previous_focus(Node.t(), term() | nil) :: Node.t() | nil
  def previous_focus(%Node{} = node, current_id \\ nil) do
    move_focus(node, current_id, -1)
  end

  @doc """
  Returns the next or previous focusable node ID.
  """
  @spec focus_id(Node.t(), :next | :previous, term() | nil) :: term() | nil
  def focus_id(node, direction, current_id \\ nil)

  def focus_id(%Node{} = node, :next, current_id), do: node |> next_focus(current_id) |> node_id()

  def focus_id(%Node{} = node, :previous, current_id),
    do: node |> previous_focus(current_id) |> node_id()

  @doc false
  @spec resize_block([String.t()], keyword()) :: [String.t()]
  def resize_block(lines, opts) do
    width = constrained_width(lines, opts)
    height = Keyword.get(opts, :height)
    align = Keyword.get(opts, :align, :left)

    lines
    |> maybe_resize_width(width, align)
    |> maybe_resize_height(height)
  end

  @doc false
  @spec resize_width([String.t()], non_neg_integer(), atom()) :: [String.t()]
  def resize_width(lines, width, align \\ :left) when is_integer(width) and width >= 0 do
    Enum.map(lines, &resize_line(&1, width, align))
  end

  @doc false
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

  defp contains?(rect, x, y) do
    x >= rect.x and x < rect.x + rect.width and y >= rect.y and y < rect.y + rect.height
  end

  defp move_focus(node, current_id, offset) do
    nodes = focusable(node)

    case nodes do
      [] -> nil
      [_ | _] -> Enum.at(nodes, next_focus_index(nodes, current_id, offset))
    end
  end

  defp next_focus_index(_nodes, nil, 1), do: 0
  defp next_focus_index(nodes, nil, -1), do: length(nodes) - 1

  defp next_focus_index(nodes, current_id, offset) do
    current_index = Enum.find_index(nodes, &(&1.id == current_id)) || fallback_index(offset)
    Integer.mod(current_index + offset, length(nodes))
  end

  defp fallback_index(1), do: -1
  defp fallback_index(-1), do: 0

  defp node_id(nil), do: nil
  defp node_id(%Node{id: id}), do: id

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
