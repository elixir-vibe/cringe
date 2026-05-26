defmodule Cringe.Widgets.Input.State do
  @moduledoc """
  Explicit state for cursor-aware input editing.
  """

  @enforce_keys [:value, :cursor]
  defstruct [:value, :cursor]

  @type t :: %__MODULE__{value: String.t(), cursor: non_neg_integer()}

  @spec new(String.t(), keyword()) :: t()
  def new(value \\ "", opts \\ []) when is_binary(value) do
    cursor =
      opts |> Keyword.get(:cursor, grapheme_count(value)) |> clamp(0, grapheme_count(value))

    %__MODULE__{value: value, cursor: cursor}
  end

  @spec value(t()) :: String.t()
  def value(%__MODULE__{value: value}), do: value

  @spec cursor(t()) :: non_neg_integer()
  def cursor(%__MODULE__{cursor: cursor}), do: cursor

  @spec insert(t(), String.t()) :: t()
  def insert(%__MODULE__{} = state, text) when is_binary(text) do
    graphemes = String.graphemes(state.value)
    {left, right} = Enum.split(graphemes, state.cursor)
    inserted = String.graphemes(text)

    (left ++ inserted ++ right)
    |> Enum.join()
    |> new(cursor: state.cursor + length(inserted))
  end

  @spec backspace(t()) :: t()
  def backspace(%__MODULE__{cursor: 0} = state), do: state

  def backspace(%__MODULE__{} = state) do
    graphemes = String.graphemes(state.value)
    {left, right} = Enum.split(graphemes, state.cursor)

    (Enum.drop(left, -1) ++ right)
    |> Enum.join()
    |> new(cursor: state.cursor - 1)
  end

  @spec delete(t()) :: t()
  def delete(%__MODULE__{} = state) do
    graphemes = String.graphemes(state.value)
    {left, right} = Enum.split(graphemes, state.cursor)

    (left ++ Enum.drop(right, 1))
    |> Enum.join()
    |> new(cursor: state.cursor)
  end

  @spec move(t(), integer()) :: t()
  def move(%__MODULE__{} = state, delta) when is_integer(delta) do
    new(state.value, cursor: state.cursor + delta)
  end

  @spec home(t()) :: t()
  def home(%__MODULE__{} = state), do: %{state | cursor: 0}

  @spec end_of_line(t()) :: t()
  def end_of_line(%__MODULE__{} = state), do: %{state | cursor: grapheme_count(state.value)}

  defp grapheme_count(value), do: String.length(value)
  defp clamp(value, min, max), do: value |> Kernel.max(min) |> Kernel.min(max)
end
