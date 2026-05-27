defmodule Cringe.Widgets.Editor.Viewport do
  @moduledoc """
  Computed visible region for `Cringe.Widgets.Editor`.
  """

  alias Cringe.Measure
  alias Cringe.Widgets.Editor.State

  @enforce_keys [:line, :column, :width, :height]
  defstruct [:line, :column, :width, :height]

  @type t :: %__MODULE__{
          line: non_neg_integer(),
          column: non_neg_integer(),
          width: pos_integer(),
          height: pos_integer()
        }

  @spec new(State.t(), pos_integer(), pos_integer()) :: t()
  def new(%State{} = state, width, height)
      when is_integer(width) and width > 0 and is_integer(height) and height > 0 do
    %__MODULE__{
      line: line_start(state, height),
      column: column_start(state, width),
      width: width,
      height: height
    }
  end

  @spec line_start(State.t(), pos_integer()) :: non_neg_integer()
  def line_start(%State{} = state, height) when is_integer(height) and height > 0 do
    max_start = max(length(state.lines) - height, 0)

    state.cursor_line
    |> min(max_start)
    |> max(0)
  end

  @spec column_start(State.t(), pos_integer()) :: non_neg_integer()
  def column_start(%State{} = state, width) when is_integer(width) and width > 0 do
    cursor_width = cursor_width(state)
    max(cursor_width - width + 1, 0)
  end

  @spec cursor_column(State.t(), t()) :: pos_integer()
  def cursor_column(%State{} = state, %__MODULE__{} = viewport) do
    state
    |> cursor_width()
    |> Kernel.-(viewport.column)
    |> max(0)
    |> Kernel.+(1)
  end

  defp cursor_width(%State{} = state) do
    state
    |> State.current_line()
    |> String.graphemes()
    |> Enum.take(state.cursor_col)
    |> Enum.join()
    |> Measure.width()
  end
end
