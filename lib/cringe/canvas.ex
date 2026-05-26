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
  def put(%__MODULE__{} = canvas, 0, y, text)
      when is_integer(y) and y >= 0 and is_binary(text) do
    if y < canvas.height do
      update_line(canvas, y, fn _line -> fit_line(text, canvas.width) end)
    else
      canvas
    end
  end

  def put(%__MODULE__{} = canvas, x, y, text)
      when is_integer(x) and x >= 0 and is_integer(y) and y >= 0 and is_binary(text) do
    if y < canvas.height and x < canvas.width do
      update_line(canvas, y, &put_text(&1, x, text, canvas.width))
    else
      canvas
    end
  end

  @spec put_block(t(), non_neg_integer(), non_neg_integer(), [String.t()]) :: t()
  def put_block(%__MODULE__{} = canvas, 0, y, lines)
      when is_integer(y) and y >= 0 and is_list(lines) do
    if y < canvas.height do
      replacements =
        lines
        |> Enum.take(canvas.height - y)
        |> Enum.map(&fit_line(&1, canvas.width))

      %{canvas | lines: replace_lines(canvas.lines, y, replacements)}
    else
      canvas
    end
  end

  def put_block(%__MODULE__{} = canvas, x, y, lines) when is_list(lines) do
    lines
    |> Enum.with_index(y)
    |> Enum.reduce(canvas, fn {line, row}, acc -> put(acc, x, row, line) end)
  end

  @spec put_block(t(), non_neg_integer(), non_neg_integer(), [String.t()], keyword()) :: t()
  def put_block(%__MODULE__{} = canvas, x, y, lines, opts)
      when is_list(lines) and is_list(opts) do
    case Keyword.get(opts, :clip) do
      nil -> put_block(canvas, x, y, lines)
      %Cringe.Rect{} = clip -> put_clipped_block(canvas, x, y, lines, clip)
    end
  end

  @spec lines(t()) :: [String.t()]
  def lines(%__MODULE__{lines: lines}), do: lines

  defp update_line(canvas, y, fun) do
    lines = List.update_at(canvas.lines, y, fun)
    %{canvas | lines: lines}
  end

  defp replace_lines(lines, y, replacements) do
    {prefix, rest} = Enum.split(lines, y)
    prefix ++ replacements ++ Enum.drop(rest, length(replacements))
  end

  defp put_clipped_block(canvas, x, y, lines, clip) do
    lines
    |> Enum.with_index(y)
    |> Enum.reduce(canvas, fn {line, row}, acc -> put_clipped_line(acc, x, row, line, clip) end)
  end

  defp put_clipped_line(canvas, x, y, line, clip) do
    line_width = Measure.width(line)
    left = max(x, clip.x)
    right = min(x + line_width, clip.x + clip.width)

    if y >= clip.y and y < clip.y + clip.height and right > left do
      visible = line |> Measure.drop(left - x) |> Measure.take(right - left)
      put(canvas, left, y, visible)
    else
      canvas
    end
  end

  defp fit_line(text, width) do
    text
    |> Measure.take(width)
    |> Measure.pad(width)
  end

  defp put_text(line, x, text, width) do
    left = Measure.take(line, x)
    visible_width = min(Measure.width(text), width - x)
    visible = Measure.take(text, visible_width)
    right = line |> drop_visible(x + visible_width) |> Measure.take(width)

    Measure.pad(left <> visible <> right, width)
  end

  defp drop_visible(line, count) do
    line
    |> Cringe.ANSI.strip()
    |> String.graphemes()
    |> Enum.drop(count)
    |> Enum.join()
  end

  defp blank(width), do: String.duplicate(" ", width)
end
