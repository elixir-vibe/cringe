defmodule Cringe.Widgets.Editor.State do
  @moduledoc """
  Explicit state for multiline text editing.
  """

  @enforce_keys [:lines, :cursor_line, :cursor_col]
  defstruct [:lines, :cursor_line, :cursor_col]

  @type t :: %__MODULE__{
          lines: [String.t()],
          cursor_line: non_neg_integer(),
          cursor_col: non_neg_integer()
        }

  @spec new(String.t() | [String.t()], keyword()) :: t()
  def new(value \\ "", opts \\ [])

  def new(value, opts) when is_binary(value) do
    value
    |> String.split("\n", trim: false)
    |> new(opts)
  end

  def new(lines, opts) when is_list(lines) do
    lines = if lines == [], do: [""], else: Enum.map(lines, &to_string/1)

    cursor_line =
      opts |> Keyword.get(:cursor_line, length(lines) - 1) |> clamp(0, length(lines) - 1)

    line = line_at(lines, cursor_line)

    cursor_col =
      opts |> Keyword.get(:cursor_col, grapheme_count(line)) |> clamp(0, grapheme_count(line))

    %__MODULE__{lines: lines, cursor_line: cursor_line, cursor_col: cursor_col}
  end

  @spec value(t()) :: String.t()
  def value(%__MODULE__{} = state), do: Enum.join(state.lines, "\n")

  @spec current_line(t()) :: String.t()
  def current_line(%__MODULE__{} = state), do: line_at(state.lines, state.cursor_line)

  @spec insert(t(), String.t()) :: t()
  def insert(%__MODULE__{} = state, text) when is_binary(text) do
    text
    |> String.split("\n", trim: false)
    |> insert_parts(state)
  end

  @spec backspace(t()) :: t()
  def backspace(%__MODULE__{cursor_line: 0, cursor_col: 0} = state), do: state

  def backspace(%__MODULE__{cursor_col: 0} = state) do
    previous = line_at(state.lines, state.cursor_line - 1)
    current = current_line(state)
    merged = previous <> current

    lines =
      state.lines
      |> List.replace_at(state.cursor_line - 1, merged)
      |> List.delete_at(state.cursor_line)

    new(lines, cursor_line: state.cursor_line - 1, cursor_col: grapheme_count(previous))
  end

  def backspace(%__MODULE__{} = state) do
    update_current_line(state, fn graphemes ->
      {left, right} = Enum.split(graphemes, state.cursor_col)
      {Enum.drop(left, -1) ++ right, state.cursor_col - 1}
    end)
  end

  @spec delete(t()) :: t()
  def delete(%__MODULE__{} = state) do
    line = current_line(state)

    cond do
      state.cursor_col < grapheme_count(line) ->
        update_current_line(state, fn graphemes ->
          {left, right} = Enum.split(graphemes, state.cursor_col)
          {left ++ Enum.drop(right, 1), state.cursor_col}
        end)

      state.cursor_line < length(state.lines) - 1 ->
        next = line_at(state.lines, state.cursor_line + 1)

        lines =
          state.lines
          |> List.replace_at(state.cursor_line, line <> next)
          |> List.delete_at(state.cursor_line + 1)

        new(lines, cursor_line: state.cursor_line, cursor_col: state.cursor_col)

      true ->
        state
    end
  end

  @spec move(t(), :left | :right | :up | :down) :: t()
  def move(%__MODULE__{cursor_col: 0, cursor_line: 0} = state, :left), do: state

  def move(%__MODULE__{cursor_col: col} = state, :left) when col > 0,
    do: %{state | cursor_col: col - 1}

  def move(%__MODULE__{} = state, :left) do
    previous = line_at(state.lines, state.cursor_line - 1)
    %{state | cursor_line: state.cursor_line - 1, cursor_col: grapheme_count(previous)}
  end

  def move(%__MODULE__{} = state, :right) do
    line_width = state |> current_line() |> grapheme_count()

    cond do
      state.cursor_col < line_width ->
        %{state | cursor_col: state.cursor_col + 1}

      state.cursor_line < length(state.lines) - 1 ->
        %{state | cursor_line: state.cursor_line + 1, cursor_col: 0}

      true ->
        state
    end
  end

  def move(%__MODULE__{cursor_line: 0} = state, :up), do: state

  def move(%__MODULE__{} = state, :up) do
    move_vertical(state, state.cursor_line - 1)
  end

  def move(%__MODULE__{} = state, :down) do
    if state.cursor_line < length(state.lines) - 1 do
      move_vertical(state, state.cursor_line + 1)
    else
      state
    end
  end

  @spec home(t()) :: t()
  def home(%__MODULE__{} = state), do: %{state | cursor_col: 0}

  @spec end_of_line(t()) :: t()
  def end_of_line(%__MODULE__{} = state),
    do: %{state | cursor_col: state |> current_line() |> grapheme_count()}

  defp insert_parts([text], %__MODULE__{} = state) do
    update_current_line(state, fn graphemes ->
      {left, right} = Enum.split(graphemes, state.cursor_col)
      inserted = String.graphemes(text)
      {left ++ inserted ++ right, state.cursor_col + length(inserted)}
    end)
  end

  defp insert_parts(parts, %__MODULE__{} = state) do
    line = current_line(state)
    {left, right} = Enum.split(String.graphemes(line), state.cursor_col)
    first = IO.iodata_to_binary([Enum.join(left), List.first(parts)])
    last_part = List.last(parts)
    last = IO.iodata_to_binary([last_part, Enum.join(right)])
    middle = parts |> Enum.drop(1) |> Enum.drop(-1)
    replacement = [first] ++ middle ++ [last]

    lines =
      state.lines
      |> List.delete_at(state.cursor_line)
      |> List.insert_at(state.cursor_line, replacement)
      |> List.flatten()

    new(lines,
      cursor_line: state.cursor_line + length(replacement) - 1,
      cursor_col: grapheme_count(last_part)
    )
  end

  defp update_current_line(%__MODULE__{} = state, fun) do
    line = current_line(state)
    {graphemes, cursor_col} = fun.(String.graphemes(line))
    lines = List.replace_at(state.lines, state.cursor_line, Enum.join(graphemes))
    new(lines, cursor_line: state.cursor_line, cursor_col: cursor_col)
  end

  defp move_vertical(%__MODULE__{} = state, cursor_line) do
    line = line_at(state.lines, cursor_line)
    %{state | cursor_line: cursor_line, cursor_col: min(state.cursor_col, grapheme_count(line))}
  end

  defp line_at([line | _lines], 0), do: line
  defp line_at([_line | lines], index), do: line_at(lines, index - 1)

  defp grapheme_count(value), do: String.length(value)
  defp clamp(value, min, max), do: value |> Kernel.max(min) |> Kernel.min(max)
end
