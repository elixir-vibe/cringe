defmodule Cringe.Canvas do
  @moduledoc """
  Fixed-size render surface for terminal lines.
  """

  alias Cringe.Measure

  @enforce_keys [:width, :height, :lines]
  defstruct [:width, :height, :lines]

  @type t :: %__MODULE__{width: non_neg_integer(), height: non_neg_integer(), lines: [String.t()]}

  @spec new(non_neg_integer(), non_neg_integer()) :: t()
  def new(width, height) when width >= 0 and height >= 0 do
    %__MODULE__{width: width, height: height, lines: List.duplicate(blank(width), height)}
  end

  @spec put(t(), non_neg_integer(), non_neg_integer(), String.t()) :: t()
  def put(%__MODULE__{} = canvas, x, y, text)
      when is_integer(x) and x >= 0 and is_integer(y) and y >= 0 and is_binary(text) do
    if y < canvas.height and x < canvas.width do
      update_line(canvas, y, &put_text(&1, x, text, canvas.width))
    else
      canvas
    end
  end

  @spec put_block(t(), non_neg_integer(), non_neg_integer(), [String.t()]) :: t()
  def put_block(%__MODULE__{} = canvas, x, y, lines) when is_list(lines) do
    lines
    |> Enum.with_index(y)
    |> Enum.reduce(canvas, fn {line, row}, acc -> put(acc, x, row, line) end)
  end

  @spec lines(t()) :: [String.t()]
  def lines(%__MODULE__{lines: lines}), do: lines

  defp update_line(canvas, y, fun) do
    lines = List.update_at(canvas.lines, y, fun)
    %{canvas | lines: lines}
  end

  defp put_text(line, x, text, width) do
    left = Measure.take(line, x)
    visible_width = min(Measure.width(text), width - x)
    visible = take_ansi_prefix(text, visible_width)
    right = line |> drop_visible(x + visible_width) |> Measure.take(width)

    Measure.pad(left <> visible <> right, width)
  end

  defp take_ansi_prefix(text, width), do: take_ansi_prefix(text, width, 0, "")

  defp take_ansi_prefix("", _width, _visible, acc), do: acc

  defp take_ansi_prefix(<<"\e[", rest::binary>>, width, visible, acc) do
    {escape, rest} = take_escape(rest, "\e[")
    take_ansi_prefix(rest, width, visible, acc <> escape)
  end

  defp take_ansi_prefix(_text, width, visible, acc) when visible >= width, do: acc

  defp take_ansi_prefix(text, width, visible, acc) do
    case String.next_grapheme(text) do
      {grapheme, rest} -> take_ansi_prefix(rest, width, visible + 1, acc <> grapheme)
      nil -> acc
    end
  end

  defp take_escape(<<"m", rest::binary>>, acc), do: {acc <> "m", rest}

  defp take_escape(<<char::binary-size(1), rest::binary>>, acc),
    do: take_escape(rest, acc <> char)

  defp take_escape("", acc), do: {acc, ""}

  defp drop_visible(line, count) do
    line
    |> Cringe.ANSI.strip()
    |> String.graphemes()
    |> Enum.drop(count)
    |> Enum.join()
  end

  defp blank(width), do: String.duplicate(" ", width)
end
