defmodule Cringe.Renderer do
  @moduledoc """
  Renders Cringe documents into terminal text.
  """

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
    Frame.new(node.lines, cursor: node.cursor)
  end
end
