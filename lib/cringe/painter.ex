defmodule Cringe.Painter do
  @moduledoc """
  Stateful terminal frame painter.

  The painter returns ANSI iodata for changed lines only after the first frame.
  """

  alias Cringe.Frame

  @enforce_keys [:width, :height]
  defstruct [:width, :height, previous: []]

  @type t :: %__MODULE__{width: pos_integer(), height: pos_integer(), previous: [String.t()]}

  @spec new(pos_integer(), pos_integer()) :: t()
  def new(width, height), do: %__MODULE__{width: width, height: height}

  @spec render(t(), Cringe.Document.t() | Frame.t()) :: {IO.chardata(), t()}
  def render(%__MODULE__{} = painter, %Frame{} = frame) do
    lines = frame.lines |> Enum.take(painter.height)
    output = output(paint(painter.previous, lines), paint_cursor(frame.cursor))
    {output, %{painter | previous: lines}}
  end

  def render(%__MODULE__{} = painter, document) do
    frame = Cringe.Renderer.frame(document, width: painter.width, height: painter.height)
    render(painter, frame)
  end

  defp paint([], lines), do: ["\e[H\e[2J", paint_all(lines)]

  defp paint(previous, lines) do
    previous
    |> changed_lines(lines)
    |> Enum.map(fn {row, line} -> ["\e[", Integer.to_string(row), ";1H\e[2K", line] end)
  end

  defp paint_all(lines) do
    lines
    |> Enum.with_index(1)
    |> Enum.map(fn {line, row} -> ["\e[", Integer.to_string(row), ";1H", line] end)
  end

  defp changed_lines(previous, lines) do
    previous
    |> pad_to(length(lines))
    |> Enum.zip(lines)
    |> Enum.with_index(1)
    |> Enum.reject(fn {{old, new}, _row} -> old == new end)
    |> Enum.map(fn {{_old, new}, row} -> {row, new} end)
  end

  defp output([], []), do: []
  defp output(paint, cursor), do: [paint, cursor]

  defp paint_cursor(nil), do: []

  defp paint_cursor({row, col}),
    do: ["\e[", Integer.to_string(row), ";", Integer.to_string(col), "H"]

  defp pad_to(lines, size), do: lines ++ List.duplicate("", max(size - length(lines), 0))
end
