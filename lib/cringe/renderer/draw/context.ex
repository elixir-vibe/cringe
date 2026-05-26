defmodule Cringe.Renderer.Draw.Context do
  @moduledoc false

  alias Cringe.Canvas
  alias Cringe.Rect

  @enforce_keys [:canvas, :ansi?]
  defstruct [:canvas, :ansi?, clip: nil]

  @type t :: %__MODULE__{canvas: Canvas.t(), ansi?: boolean(), clip: Rect.t() | nil}

  @spec new(Canvas.t(), keyword()) :: t()
  def new(%Canvas{} = canvas, opts \\ []) do
    %__MODULE__{
      canvas: canvas,
      ansi?: Keyword.get(opts, :ansi, false),
      clip: Keyword.get(opts, :clip)
    }
  end

  @spec put_block(t(), non_neg_integer(), non_neg_integer(), [String.t()]) :: t()
  def put_block(%__MODULE__{clip: nil} = context, x, y, lines) do
    %{context | canvas: Canvas.put_block(context.canvas, x, y, lines)}
  end

  def put_block(%__MODULE__{clip: %Rect{} = clip} = context, x, y, lines) do
    %{context | canvas: Canvas.put_block(context.canvas, x, y, lines, clip: clip)}
  end

  @spec with_canvas(t(), Canvas.t()) :: t()
  def with_canvas(%__MODULE__{} = context, %Canvas{} = canvas), do: %{context | canvas: canvas}

  @spec clip(t(), Rect.t() | nil) :: t()
  def clip(%__MODULE__{} = context, nil), do: context

  def clip(%__MODULE__{} = context, %Rect{} = clip),
    do: %{context | clip: intersect(context.clip, clip)}

  defp intersect(nil, clip), do: clip

  defp intersect(%Rect{} = first, %Rect{} = second) do
    left = max(first.x, second.x)
    top = max(first.y, second.y)
    right = min(first.x + first.width, second.x + second.width)
    bottom = min(first.y + first.height, second.y + second.height)

    Rect.new(left, top, max(right - left, 0), max(bottom - top, 0))
  end
end
