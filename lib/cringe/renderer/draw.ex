defmodule Cringe.Renderer.Draw do
  @moduledoc """
  Draws layout nodes into terminal frames.
  """

  alias Cringe.ANSI
  alias Cringe.Canvas
  alias Cringe.Document.{Box, Stack, Text}
  alias Cringe.Frame
  alias Cringe.Layout.Node
  alias Cringe.Rect
  alias Cringe.Renderer.Draw.Box, as: BoxDraw

  @spec frame(Node.t(), keyword()) :: Frame.t()
  def frame(%Node{} = node, opts \\ []) do
    width = Keyword.get(opts, :width, node.rect.width)
    height = Keyword.get(opts, :height, node.rect.height)

    node
    |> draw(Canvas.new(width, height), opts)
    |> Canvas.lines()
    |> Frame.new(cursor: node.cursor)
  end

  @spec draw(Node.t(), Canvas.t(), keyword()) :: Canvas.t()
  def draw(%Node{} = node, %Canvas{} = canvas, opts \\ []) do
    draw_at(canvas, node, {node.rect.x, node.rect.y}, opts)
  end

  defp draw_at(%Canvas{} = canvas, %Node{document: %Text{opts: text_opts}} = node, {x, y}, opts) do
    ansi? = Keyword.get(opts, :ansi, false)
    lines = Enum.map(node.lines, &ANSI.apply(&1, text_opts, ansi?))

    put_block(canvas, x, y, lines, opts)
  end

  defp draw_at(%Canvas{} = canvas, %Node{document: %Stack{}} = node, origin, opts) do
    draw_children(canvas, node, origin, opts)
  end

  defp draw_at(%Canvas{} = canvas, %Node{document: %Box{opts: box_opts}} = node, {x, y}, opts) do
    rect = Rect.new(x, y, node.rect.width, node.rect.height)
    clip = box_clip(rect, box_opts)

    canvas
    |> BoxDraw.border(rect, Keyword.get(box_opts, :border, :rounded))
    |> draw_box_children(node, {x, y}, opts, clip, Keyword.get(box_opts, :scroll_y, 0))
  end

  defp draw_box_children(canvas, node, {x, y}, opts, clip, scroll_y) do
    Enum.reduce(node.children, canvas, fn child, acc ->
      origin = {x + child.rect.x, y + child.rect.y - scroll_y}
      draw_at(acc, child, origin, Keyword.put(opts, :clip, clip))
    end)
  end

  defp draw_children(%Canvas{} = canvas, %Node{} = node, {x, y}, opts) do
    Enum.reduce(node.children, canvas, fn child, acc ->
      draw_at(acc, child, {x + child.rect.x, y + child.rect.y}, opts)
    end)
  end

  defp box_clip(rect, opts) do
    if Keyword.get(opts, :overflow) == :hidden do
      BoxDraw.content_rect(
        rect,
        Keyword.get(opts, :padding, 0),
        Keyword.get(opts, :border, :rounded)
      )
    end
  end

  defp put_block(canvas, x, y, lines, opts) do
    case Keyword.get(opts, :clip) do
      nil -> Canvas.put_block(canvas, x, y, lines)
      %Rect{} = clip -> Canvas.put_block(canvas, x, y, lines, clip: clip)
    end
  end
end
