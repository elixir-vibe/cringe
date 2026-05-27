defmodule Cringe.Widgets.Table.State do
  @moduledoc """
  Explicit row-selection state for `Cringe.Widgets.Table`.
  """

  alias Cringe.Widgets.Table.Row

  @enforce_keys [:rows]
  defstruct rows: [], selected: nil, max_visible: nil

  @type t :: %__MODULE__{
          rows: [Row.t()],
          selected: non_neg_integer() | nil,
          max_visible: pos_integer() | nil
        }

  @spec new([Row.t() | keyword() | map()], keyword()) :: t()
  def new(rows, opts \\ []) when is_list(rows) do
    rows = Enum.map(rows, &Row.new/1)
    selected = Keyword.get(opts, :selected)

    %__MODULE__{rows: rows, selected: selected, max_visible: Keyword.get(opts, :max_visible)}
    |> clamp_selected()
  end

  @spec selected_row(t()) :: Row.t() | nil
  def selected_row(%__MODULE__{selected: nil}), do: nil
  def selected_row(%__MODULE__{} = state), do: Enum.at(state.rows, state.selected)

  @spec move(t(), integer()) :: t()
  def move(%__MODULE__{selected: nil} = state, _delta), do: state

  def move(%__MODULE__{} = state, delta) when is_integer(delta) do
    case length(state.rows) do
      0 -> %{state | selected: nil}
      count -> %{state | selected: (state.selected + delta) |> max(0) |> min(count - 1)}
    end
  end

  @spec clamp_selected(t()) :: t()
  def clamp_selected(%__MODULE__{selected: nil} = state), do: state

  def clamp_selected(%__MODULE__{} = state) do
    case length(state.rows) do
      0 -> %{state | selected: nil}
      count -> %{state | selected: state.selected |> max(0) |> min(count - 1)}
    end
  end
end
