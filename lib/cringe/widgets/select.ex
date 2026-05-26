defmodule Cringe.Widgets.Select do
  @moduledoc """
  Render-only select/list widget.
  """

  alias Cringe.Document.Stack

  @spec new(keyword()) :: Cringe.Document.t()
  def new(opts \\ []) do
    options = Keyword.get(opts, :options, [])
    selected = Keyword.get(opts, :selected, 0)
    marker = Keyword.get(opts, :marker, "›")
    blank = String.duplicate(" ", Cringe.Measure.width(marker))

    options
    |> Enum.with_index()
    |> Enum.map(fn {option, index} ->
      prefix = if index == selected, do: marker, else: blank
      Cringe.text(prefix <> " " <> to_string(option))
    end)
    |> Stack.new(:vertical, Keyword.drop(opts, [:options, :selected, :marker]))
  end
end
