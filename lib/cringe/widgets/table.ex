defmodule Cringe.Widgets.Table do
  @moduledoc """
  Generic terminal table with fixed columns and optional row selection.

  Tables render rows from struct-backed columns and row data. Selection is
  optional: pass `selected: index` or keep `selected` as `nil` for display-only
  tables.

      alias Cringe.Widgets.Table
      alias Cringe.Widgets.Table.State

      columns = [%{id: :name, label: "Name", width: 12}]
      state = State.new([%{name: "Jobs"}], selected: 0)
      {:select, _row, ^state} = Table.update(state, Cringe.Event.key(:enter))

  `update/3` accepts a custom `Cringe.Keymap`.
  """

  alias Cringe.Document.Stack
  alias Cringe.Keymap
  alias Cringe.Measure
  alias Cringe.Widgets.Table.Column
  alias Cringe.Widgets.Table.Row
  alias Cringe.Widgets.Table.State

  @separator "  "
  @marker "› "
  @blank "  "

  @type update_result :: {:ok, State.t()} | {:select, Row.t(), State.t()} | :ignored

  @spec new(keyword()) :: Cringe.Document.t()
  def new(opts \\ []) do
    columns = opts |> Keyword.get(:columns, []) |> Enum.map(&Column.new/1)
    state = state_from_opts(opts)
    width = Keyword.get(opts, :width, 80)
    show_header? = Keyword.get(opts, :header, true)

    lines(columns, state, width, show_header?)
    |> Stack.new(:vertical, container_opts(opts))
  end

  @spec render(State.t(), [Column.t() | keyword() | map()], keyword()) :: Cringe.Document.t()
  def render(%State{} = state, columns, opts \\ []) do
    opts |> Keyword.put(:state, state) |> Keyword.put(:columns, columns) |> new()
  end

  @spec default_keymap() :: Keymap.t()
  def default_keymap do
    Keymap.new(next: [:down, :j], previous: [:up, :k], select: [:enter])
  end

  @spec update(State.t(), Cringe.Event.t()) :: update_result()
  def update(%State{} = state, event), do: update(state, event, default_keymap())

  @spec update(State.t(), Cringe.Event.t(), Keymap.t()) :: update_result()
  def update(%State{} = state, event, %Keymap{} = keymap) do
    case Keymap.action(keymap, event) do
      {:ok, :next} -> {:ok, State.move(state, 1)}
      {:ok, :previous} -> {:ok, State.move(state, -1)}
      {:ok, :select} -> select_row(state)
      _ -> :ignored
    end
  end

  @spec lines([Column.t()], State.t(), pos_integer(), boolean()) :: [Cringe.Document.t()]
  def lines(columns, %State{} = state, width, show_header?) do
    widths = column_widths(columns, state.rows, width)
    rows = visible_rows(state)

    header =
      if show_header?, do: [line(columns, header_row(columns), widths, false, :header)], else: []

    body =
      rows
      |> Enum.with_index(visible_start(state))
      |> Enum.map(fn {%Row{} = row, index} ->
        line(columns, row, widths, index == state.selected, :body)
      end)

    header ++ body
  end

  defp state_from_opts(opts) do
    case Keyword.get(opts, :state) do
      %State{} = state ->
        state

      nil ->
        State.new(Keyword.get(opts, :rows, []),
          selected: Keyword.get(opts, :selected),
          max_visible: Keyword.get(opts, :max_visible)
        )
    end
  end

  defp container_opts(opts) do
    opts
    |> Keyword.drop([:columns, :rows, :state, :selected, :max_visible, :width, :header])
    |> Keyword.put_new(:role, :table)
  end

  defp header_row(columns) do
    cells = Map.new(columns, &{&1.id, &1.label})
    %Row{cells: cells}
  end

  defp visible_rows(%State{max_visible: nil} = state), do: state.rows

  defp visible_rows(%State{} = state) do
    state.rows
    |> Enum.slice(visible_start(state), max(state.max_visible, 1))
  end

  defp visible_start(%State{max_visible: nil}), do: 0
  defp visible_start(%State{selected: nil}), do: 0

  defp visible_start(%State{} = state) do
    max_visible = max(state.max_visible, 1)
    max(0, min(state.selected - div(max_visible, 2), length(state.rows) - max_visible))
  end

  defp column_widths(columns, rows, width) do
    dynamic_columns = Enum.count(columns, &is_nil(&1.width))
    fixed_width = Enum.reduce(columns, 0, fn column, total -> total + (column.width || 0) end)
    separators = max(length(columns) - 1, 0) * Measure.width(@separator)
    marker_width = Measure.width(@marker)
    available = max(width - fixed_width - separators - marker_width, 1)
    dynamic_width = max(div(available, max(dynamic_columns, 1)), 1)

    Map.new(columns, fn %Column{} = column ->
      width = column.width || min(dynamic_width, natural_width(column, rows))
      {column.id, max(width, 1)}
    end)
  end

  defp natural_width(%Column{} = column, rows) do
    row_width = rows |> Enum.map(&cell_width(&1, column)) |> Enum.max(fn -> 0 end)
    max(Measure.width(column.label), row_width)
  end

  defp cell_width(%Row{} = row, %Column{} = column), do: row |> cell(column) |> Measure.width()

  defp line(columns, %Row{} = row, widths, selected?, role) do
    content =
      Enum.map_join(columns, @separator, &format_cell(row, &1, Map.fetch!(widths, &1.id)))

    prefix = if selected?, do: @marker, else: @blank
    style = if selected?, do: Cringe.Style.variant(:selected, role: role), else: [role: role]
    Cringe.text(prefix <> content, style)
  end

  defp format_cell(%Row{} = row, %Column{} = column, width) do
    value = row |> cell(column) |> Measure.take(width)

    case column.align do
      :right -> String.duplicate(" ", max(width - Measure.width(value), 0)) <> value
      :left -> Measure.pad(value, width)
    end
  end

  defp cell(%Row{} = row, %Column{} = column) do
    row.cells
    |> Map.get(column.id, "")
    |> to_string()
  end

  defp select_row(%State{} = state) do
    case State.selected_row(state) do
      nil -> :ignored
      %Row{} = row -> {:select, row, state}
    end
  end
end
