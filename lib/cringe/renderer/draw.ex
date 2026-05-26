defmodule Cringe.Renderer.Draw do
  @moduledoc """
  Draws layout nodes into terminal frames.
  """

  alias Cringe.ANSI
  alias Cringe.Canvas
  alias Cringe.Document.{Box, Text}
  alias Cringe.Frame
  alias Cringe.Layout.Node

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
    |> Canvas.put_block(node.rect.x, node.rect.y, node.lines)
    |> draw_text_overlays(node, {node.rect.x, node.rect.y}, opts)
  end

  defp draw_text_overlays(
         %Canvas{} = canvas,
         %Node{document: %Text{opts: text_opts}} = node,
         {x, y},
         opts
       ) do
    if Keyword.get(opts, :ansi, false) and styled?(text_opts) do
      lines = Enum.map(node.lines, &ANSI.apply(&1, text_opts, true))
      Canvas.put_block(canvas, x, y, lines)
    else
      canvas
    end
  end

  defp draw_text_overlays(
         %Canvas{} = canvas,
         %Node{document: %Box{opts: opts}} = node,
         origin,
         draw_opts
       ) do
    if Keyword.get(opts, :overflow) == :hidden do
      canvas
    else
      draw_child_text_overlays(canvas, node, origin, draw_opts)
    end
  end

  defp draw_text_overlays(%Canvas{} = canvas, %Node{} = node, origin, opts) do
    draw_child_text_overlays(canvas, node, origin, opts)
  end

  defp draw_child_text_overlays(%Canvas{} = canvas, %Node{} = node, {x, y}, opts) do
    Enum.reduce(node.children, canvas, fn child, acc ->
      draw_text_overlays(acc, child, {x + child.rect.x, y + child.rect.y}, opts)
    end)
  end

  defp styled?(opts) do
    Keyword.get(opts, :bold) == true or
      Keyword.get(opts, :italic) == true or
      Keyword.get(opts, :underline) == true or
      Keyword.has_key?(opts, :color)
  end
end
