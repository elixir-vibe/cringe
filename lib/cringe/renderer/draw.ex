defmodule Cringe.Renderer.Draw do
  @moduledoc """
  Draws layout nodes into terminal frames.
  """

  alias Cringe.ANSI
  alias Cringe.Canvas
  alias Cringe.Document.{Box, Stack, Text}
  alias Cringe.Frame
  alias Cringe.Layout
  alias Cringe.Layout.Node
  alias Cringe.Rect
  alias Cringe.Renderer.Draw.Box, as: BoxDraw
  alias Cringe.Renderer.Draw.Context

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
    canvas
    |> Context.new(opts)
    |> draw_at(node, {node.rect.x, node.rect.y})
    |> Map.fetch!(:canvas)
  end

  defp draw_at(
         %Context{} = context,
         %Node{document: %Text{content: content, opts: text_opts}} = node,
         {x, y}
       ) do
    lines =
      content
      |> String.split("\n", trim: false)
      |> Layout.resize_block(text_draw_opts(text_opts, node))
      |> Enum.map(&ANSI.apply(&1, text_opts, context.ansi?))

    Context.put_block(context, x, y, lines)
  end

  defp draw_at(%Context{} = context, %Node{document: %Stack{}} = node, origin) do
    draw_children(context, node, origin)
  end

  defp draw_at(%Context{} = context, %Node{document: %Box{opts: box_opts}} = node, {x, y}) do
    rect = Rect.new(x, y, node.rect.width, node.rect.height)

    context
    |> Context.with_canvas(
      BoxDraw.border(context.canvas, rect, Keyword.get(box_opts, :border, :rounded))
    )
    |> draw_box_children(
      node,
      {x, y},
      box_clip(rect, box_opts),
      Keyword.get(box_opts, :scroll_y, 0)
    )
  end

  defp draw_box_children(%Context{} = context, node, {x, y}, clip, scroll_y) do
    context = Context.clip(context, clip)

    Enum.reduce(node.children, context, fn child, acc ->
      draw_at(acc, child, {x + child.rect.x, y + child.rect.y - scroll_y})
    end)
  end

  defp draw_children(%Context{} = context, %Node{} = node, {x, y}) do
    Enum.reduce(node.children, context, fn child, acc ->
      draw_at(acc, child, {x + child.rect.x, y + child.rect.y})
    end)
  end

  defp text_draw_opts(text_opts, node) do
    text_opts
    |> Keyword.put(:width, node.rect.width)
    |> Keyword.put(:height, node.rect.height)
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
end
