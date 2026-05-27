defmodule Cringe.Widgets.Table.Row do
  @moduledoc """
  Row data for `Cringe.Widgets.Table`.
  """

  @enforce_keys [:cells]
  defstruct [:id, cells: %{}]

  @type t :: %__MODULE__{id: term(), cells: %{optional(term()) => term()}}

  @spec new(keyword() | map()) :: t()
  def new(%__MODULE__{} = row), do: row

  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)
    cells = Map.get(attrs, :cells, attrs |> Map.drop([:id]) |> normalize_cell_keys())
    %__MODULE__{id: Map.get(attrs, :id), cells: normalize_cell_keys(cells)}
  end

  defp normalize_cell_keys(cells) when is_list(cells),
    do: cells |> Map.new() |> normalize_cell_keys()

  defp normalize_cell_keys(cells) when is_map(cells), do: Map.new(cells)
end
