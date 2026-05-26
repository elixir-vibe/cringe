defmodule Cringe.Renderer.Draw do
  @moduledoc """
  Draws layout nodes into terminal frames.
  """

  alias Cringe.Canvas
  alias Cringe.Frame
  alias Cringe.Layout.Node

  @spec frame(Node.t(), keyword()) :: Frame.t()
  def frame(%Node{} = node, opts \\ []) do
    width = Keyword.get(opts, :width, node.rect.width)
    height = Keyword.get(opts, :height, node.rect.height)

    node
    |> draw(Canvas.new(width, height))
    |> Canvas.lines()
    |> Frame.new(cursor: node.cursor)
  end

  @spec draw(Node.t(), Canvas.t()) :: Canvas.t()
  def draw(%Node{} = node, %Canvas{} = canvas) do
    Canvas.put_block(canvas, node.rect.x, node.rect.y, node.lines)
  end
end
