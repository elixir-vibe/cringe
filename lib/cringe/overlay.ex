defmodule Cringe.Overlay do
  @moduledoc """
  Pure document overlay composition.

  Overlay state is ordered from bottom to top. Rendering composites a base
  document and each overlay layer into one frame. Runtime input routing is left
  to callers; `Cringe.Overlay.State.capturing/1` returns the topmost capturing
  layer when apps need that policy.
  """

  alias Cringe.Canvas
  alias Cringe.Frame
  alias Cringe.Measure
  alias Cringe.Overlay.{Layer, State}
  alias Cringe.Rect

  @type render_opts :: [width: pos_integer(), height: pos_integer(), ansi: boolean()]

  @spec new([Layer.t()]) :: State.t()
  def new(layers \\ []), do: State.new(layers)

  @spec layer(term(), Cringe.Document.t(), keyword()) :: Layer.t()
  def layer(id, document, opts \\ []), do: Layer.new(id, document, opts)

  @spec put(State.t(), Layer.t()) :: State.t()
  def put(%State{} = state, %Layer{} = layer), do: State.put(state, layer)

  @spec remove(State.t(), term()) :: State.t()
  def remove(%State{} = state, id), do: State.remove(state, id)

  @spec frame(Cringe.Document.t(), State.t(), render_opts()) :: Frame.t()
  def frame(base, %State{} = state, opts) do
    width = Keyword.fetch!(opts, :width)
    height = Keyword.fetch!(opts, :height)
    ansi? = Keyword.get(opts, :ansi, false)
    base_frame = Cringe.Renderer.frame(base, width: width, height: height, ansi: ansi?)

    canvas =
      width
      |> Canvas.new(height)
      |> Canvas.put_block(0, 0, base_frame.lines)

    {canvas, cursor} =
      Enum.reduce(state.layers, {canvas, base_frame.cursor}, fn %Layer{} = layer,
                                                                {canvas, cursor} ->
        layer_frame = render_layer(layer, width, height, ansi?)
        {x, y} = position(layer, layer_frame, width, height)

        canvas =
          Canvas.put_block(canvas, x, y, layer_frame.lines, clip: Rect.new(0, 0, width, height))

        {canvas, translate_cursor(layer_frame.cursor, x, y) || cursor}
      end)

    Frame.new(Canvas.lines(canvas), cursor: cursor)
  end

  @spec render(Cringe.Document.t(), State.t(), render_opts()) :: String.t()
  def render(base, %State{} = state, opts) do
    base
    |> frame(state, opts)
    |> Frame.text()
  end

  defp render_layer(%Layer{} = layer, base_width, base_height, ansi?) do
    opts = [ansi: ansi?]

    opts =
      if layer.width,
        do: Keyword.put(opts, :width, layer.width),
        else: Keyword.put(opts, :width, base_width)

    opts = if layer.height, do: Keyword.put(opts, :height, layer.height), else: opts
    frame = Cringe.Renderer.frame(layer.document, opts)

    if is_nil(layer.width) and is_nil(layer.height) do
      trim_frame(frame)
    else
      frame
    end
    |> constrain_to_base(base_width, base_height)
  end

  defp trim_frame(%Frame{} = frame) do
    lines = Enum.map(frame.lines, &String.trim_trailing/1)
    Frame.new(lines, cursor: frame.cursor)
  end

  defp constrain_to_base(%Frame{} = frame, base_width, base_height) do
    lines = frame.lines |> Enum.take(base_height) |> Enum.map(&Measure.take(&1, base_width))
    Frame.new(lines, cursor: frame.cursor)
  end

  defp position(%Layer{x: x, y: y}, _frame, _base_width, _base_height)
       when is_integer(x) and is_integer(y),
       do: {max(x, 0), max(y, 0)}

  defp position(%Layer{} = layer, %Frame{} = frame, base_width, base_height) do
    width = frame_width(frame)
    height = length(frame.lines)
    margin = layer.margin

    case layer.anchor do
      :center ->
        {div(max(base_width - width, 0), 2), div(max(base_height - height, 0), 2)}

      :top ->
        {div(max(base_width - width, 0), 2), margin}

      :bottom ->
        {div(max(base_width - width, 0), 2), max(base_height - height - margin, 0)}

      :top_left ->
        {margin, margin}

      :top_right ->
        {max(base_width - width - margin, 0), margin}

      :bottom_left ->
        {margin, max(base_height - height - margin, 0)}

      :bottom_right ->
        {max(base_width - width - margin, 0), max(base_height - height - margin, 0)}
    end
  end

  defp frame_width(%Frame{} = frame) do
    frame.lines
    |> Enum.map(&Measure.width/1)
    |> Enum.max(fn -> 0 end)
  end

  defp translate_cursor(nil, _x, _y), do: nil
  defp translate_cursor({row, col}, x, y), do: {row + y, col + x}
end
