defmodule Cringe.Layout.Node do
  @moduledoc """
  Positioned result of laying out a document node.
  """

  alias Cringe.Layout.Size
  alias Cringe.Measure
  alias Cringe.Rect

  @enforce_keys [:document, :rect, :size, :content_rect, :lines]
  defstruct [:document, :rect, :size, :content_rect, :lines, children: [], cursor: nil, id: nil]

  @type t :: %__MODULE__{
          document: Cringe.Document.t(),
          rect: Rect.t(),
          size: Size.t(),
          content_rect: Rect.t(),
          lines: [String.t()],
          children: [t()],
          cursor: {pos_integer(), pos_integer()} | nil,
          id: term() | nil
        }

  @spec new(Cringe.Document.t(), [String.t()], keyword()) :: t()
  def new(document, lines, opts \\ []) do
    x = Keyword.get(opts, :x, 0)
    y = Keyword.get(opts, :y, 0)
    children = Keyword.get(opts, :children, [])
    cursor = Keyword.get(opts, :cursor)
    id = Keyword.get(opts, :id, document_id(document))
    size = Size.new(width(lines), length(lines))
    rect = Rect.new(x, y, size.width, size.height)

    %__MODULE__{
      document: document,
      rect: rect,
      size: size,
      content_rect: Keyword.get(opts, :content_rect, rect),
      lines: lines,
      children: children,
      cursor: cursor,
      id: id
    }
  end

  defp document_id(%{opts: opts}) when is_list(opts), do: Keyword.get(opts, :id)
  defp document_id(_document), do: nil

  defp width(lines) do
    lines
    |> Enum.map(&Measure.width/1)
    |> Enum.max(fn -> 0 end)
  end
end
