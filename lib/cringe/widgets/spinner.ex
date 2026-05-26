defmodule Cringe.Widgets.Spinner do
  @moduledoc """
  Render-only spinner widget.
  """

  @frames ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]

  @spec new(keyword()) :: Cringe.Document.t()
  def new(opts \\ []) do
    frames = Keyword.get(opts, :frames, @frames)
    frame = opts |> Keyword.get(:frame, 0) |> frame_at(frames)
    label = Keyword.get(opts, :label, "")
    separator = if label == "", do: "", else: " "

    Cringe.text(frame <> separator <> label, Keyword.drop(opts, [:frame, :frames, :label]))
  end

  defp frame_at(_index, []), do: ""

  defp frame_at(index, frames) when is_integer(index),
    do: Enum.at(frames, rem(index, length(frames)))

  defp frame_at(frame, _frames) when is_binary(frame), do: frame
  defp frame_at(_frame, frames), do: List.first(frames)
end
