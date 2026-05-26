defmodule Cringe.Widgets.Progress do
  @moduledoc """
  Render-only progress bar widget.
  """

  @spec new(keyword()) :: Cringe.Document.t()
  def new(opts \\ []) do
    value = opts |> Keyword.get(:value, 0.0) |> clamp()
    width = Keyword.get(opts, :width, 20)
    filled = round(value * width)
    empty = max(width - filled, 0)
    label = Keyword.get(opts, :label)

    bar = "[" <> String.duplicate("█", filled) <> String.duplicate("░", empty) <> "]"
    content = if label, do: "#{label} #{bar}", else: bar

    Cringe.text(content, Keyword.drop(opts, [:value, :width, :label]))
  end

  defp clamp(value) when is_integer(value), do: (value / 1) |> clamp()
  defp clamp(value) when is_float(value), do: value |> max(0.0) |> min(1.0)
  defp clamp(_value), do: 0.0
end
