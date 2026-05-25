defmodule Cringe.Layout.Node do
  @moduledoc """
  Positioned result of laying out a document node.
  """

  alias Cringe.Layout.Size
  alias Cringe.Measure
  alias Cringe.Rect

  @enforce_keys [:document, :rect, :size, :lines]
  defstruct [:document, :rect, :size, :lines, children: []]

  @type t :: %__MODULE__{
          document: Cringe.Document.t(),
          rect: Rect.t(),
          size: Size.t(),
          lines: [String.t()],
          children: [t()]
        }

  @spec new(Cringe.Document.t(), [String.t()], keyword()) :: t()
  def new(document, lines, opts \\ []) do
    x = Keyword.get(opts, :x, 0)
    y = Keyword.get(opts, :y, 0)
    children = Keyword.get(opts, :children, [])
    size = Size.new(width(lines), length(lines))

    %__MODULE__{
      document: document,
      rect: Rect.new(x, y, size.width, size.height),
      size: size,
      lines: lines,
      children: children
    }
  end

  defp width(lines) do
    lines
    |> Enum.map(&Measure.width/1)
    |> Enum.max(fn -> 0 end)
  end
end
