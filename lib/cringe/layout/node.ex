defmodule Cringe.Layout.Node do
  @moduledoc """
  Positioned result of laying out a document node.
  """

  alias Cringe.Layout.Size
  alias Cringe.Measure
  alias Cringe.Rect

  @enforce_keys [:document, :rect, :size, :content_rect, :lines]
  defstruct [
    :document,
    :rect,
    :size,
    :content_rect,
    :lines,
    children: [],
    cursor: nil,
    id: nil,
    role: nil,
    focusable?: false
  ]

  @type t :: %__MODULE__{
          document: Cringe.Document.t(),
          rect: Rect.t(),
          size: Size.t(),
          content_rect: Rect.t(),
          lines: [String.t()],
          children: [t()],
          cursor: {pos_integer(), pos_integer()} | nil,
          id: term() | nil,
          role: atom() | nil,
          focusable?: boolean()
        }

  @spec new(Cringe.Document.t(), [String.t()], keyword()) :: t()
  def new(document, lines, opts \\ []) do
    size = Keyword.get_lazy(opts, :size, fn -> Size.new(width(lines), length(lines)) end)
    build(document, lines, size, opts)
  end

  @spec new_sized(Cringe.Document.t(), Size.t(), keyword()) :: t()
  def new_sized(document, %Size{} = size, opts \\ []) do
    build(document, blank_lines(size), size, opts)
  end

  defp build(document, lines, %Size{} = size, opts) do
    x = Keyword.get(opts, :x, 0)
    y = Keyword.get(opts, :y, 0)
    children = Keyword.get(opts, :children, [])
    cursor = Keyword.get(opts, :cursor)
    id = Keyword.get(opts, :id, document_opt(document, :id))
    role = Keyword.get(opts, :role, document_opt(document, :role))
    focusable? = Keyword.get(opts, :focusable?, document_focusable?(document, role))
    rect = Rect.new(x, y, size.width, size.height)

    %__MODULE__{
      document: document,
      rect: rect,
      size: size,
      content_rect: Keyword.get(opts, :content_rect, rect),
      lines: lines,
      children: children,
      cursor: cursor,
      id: id,
      role: role,
      focusable?: focusable?
    }
  end

  defp document_opt(%{opts: opts}, key) when is_list(opts), do: Keyword.get(opts, key)
  defp document_opt(_document, _key), do: nil

  defp document_focusable?(document, role) do
    document_opt(document, :focusable) == true or document_opt(document, :focusable?) == true or
      role in [:input, :select]
  end

  defp blank_lines(%Size{width: width, height: height}) do
    blank = String.duplicate(" ", width)
    List.duplicate(blank, height)
  end

  defp width(lines) do
    lines
    |> Enum.map(&Measure.width/1)
    |> Enum.max(fn -> 0 end)
  end
end
