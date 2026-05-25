defmodule Cringe.Renderer do
  @moduledoc """
  Renders Cringe documents into terminal text.
  """

  alias Cringe.Document.Text

  @type render_opts :: [width: pos_integer(), height: pos_integer()]

  @spec render(Cringe.Document.t(), render_opts()) :: String.t()
  def render(document, opts \\ []) do
    width = Keyword.get(opts, :width)
    height = Keyword.get(opts, :height)

    document
    |> lines()
    |> maybe_clip_height(height)
    |> Enum.map_join("\n", &maybe_clip_width(&1, width))
  end

  defp lines(%Text{content: content}) do
    String.split(content, "\n", trim: false)
  end

  defp maybe_clip_height(lines, nil), do: lines

  defp maybe_clip_height(lines, height) when is_integer(height) and height > 0,
    do: Enum.take(lines, height)

  defp maybe_clip_width(line, nil), do: line

  defp maybe_clip_width(line, width) when is_integer(width) and width > 0 do
    line
    |> String.graphemes()
    |> Enum.take(width)
    |> Enum.join()
  end
end
