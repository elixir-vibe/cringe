defmodule Cringe.Renderer do
  @moduledoc """
  Renders Cringe documents into terminal text.
  """

  alias Cringe.Canvas
  alias Cringe.Frame
  alias Cringe.Layout.Engine

  @type render_opts :: [width: pos_integer(), height: pos_integer(), ansi: boolean()]

  @spec render(Cringe.Document.t(), render_opts()) :: String.t()
  def render(document, opts \\ []) do
    document
    |> frame(opts)
    |> Frame.text()
  end

  @spec frame(Cringe.Document.t(), render_opts()) :: Frame.t()
  def frame(document, opts \\ []) do
    node = Engine.layout(document, opts)

    width = Keyword.get(opts, :width, node.rect.width)
    height = Keyword.get(opts, :height, node.rect.height)

    width
    |> Canvas.new(height)
    |> Canvas.put_block(0, 0, node.lines)
    |> Canvas.lines()
    |> Frame.new(cursor: node.cursor)
  end
end
