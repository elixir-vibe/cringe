defmodule Cringe.Renderer.Draw.Box do
  @moduledoc false

  alias Cringe.Canvas
  alias Cringe.Rect

  @spec border(Canvas.t(), Rect.t(), atom() | false | nil) :: Canvas.t()
  def border(%Canvas{} = canvas, %Rect{} = _rect, border) when border in [false, nil], do: canvas

  def border(%Canvas{} = canvas, %Rect{width: 0} = _rect, _border), do: canvas
  def border(%Canvas{} = canvas, %Rect{height: 0} = _rect, _border), do: canvas

  def border(%Canvas{} = canvas, %Rect{} = rect, border) do
    {top_left, top_right, bottom_left, bottom_right, horizontal, vertical} = chars(border)

    cond do
      rect.width == 1 and rect.height == 1 ->
        Canvas.put(canvas, rect.x, rect.y, top_left)

      rect.height == 1 ->
        Canvas.put(
          canvas,
          rect.x,
          rect.y,
          horizontal_rule(top_left, top_right, horizontal, rect.width)
        )

      rect.width == 1 ->
        draw_vertical_line(canvas, rect, vertical)

      true ->
        canvas
        |> Canvas.put(
          rect.x,
          rect.y,
          horizontal_rule(top_left, top_right, horizontal, rect.width)
        )
        |> draw_sides(rect, vertical)
        |> Canvas.put(
          rect.x,
          rect.y + rect.height - 1,
          horizontal_rule(bottom_left, bottom_right, horizontal, rect.width)
        )
    end
  end

  @spec content_rect(Rect.t(), non_neg_integer(), atom() | false | nil) :: Rect.t()
  def content_rect(%Rect{} = rect, padding, border) when is_integer(padding) and padding >= 0 do
    offset = padding + border_offset(border)

    Rect.new(
      rect.x + offset,
      rect.y + offset,
      max(rect.width - offset * 2, 0),
      max(rect.height - offset * 2, 0)
    )
  end

  defp draw_vertical_line(canvas, rect, vertical) do
    Enum.reduce(0..(rect.height - 1), canvas, fn row, acc ->
      Canvas.put(acc, rect.x, rect.y + row, vertical)
    end)
  end

  defp draw_sides(canvas, rect, vertical) do
    if rect.height <= 2 do
      canvas
    else
      Enum.reduce(1..(rect.height - 2), canvas, fn row, acc ->
        acc
        |> Canvas.put(rect.x, rect.y + row, vertical)
        |> Canvas.put(rect.x + rect.width - 1, rect.y + row, vertical)
      end)
    end
  end

  defp horizontal_rule(left, right, horizontal, width) do
    left <> String.duplicate(horizontal, max(width - 2, 0)) <> right
  end

  defp border_offset(false), do: 0
  defp border_offset(nil), do: 0
  defp border_offset(_border), do: 1

  defp chars(:square), do: {"+", "+", "+", "+", "-", "|"}
  defp chars(_border), do: {"╭", "╮", "╰", "╯", "─", "│"}
end
