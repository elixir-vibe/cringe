defmodule Cringe.Widgets.Menu.State do
  @moduledoc """
  Explicit state for `Cringe.Widgets.Menu`.
  """

  alias Cringe.Widgets.Menu.Entry
  alias Cringe.Widgets.Menu.Item

  @enforce_keys [:entries]
  defstruct entries: [], selected: 0, max_visible: 8, empty_label: "No menu items"

  @type t :: %__MODULE__{
          entries: [Entry.t()],
          selected: non_neg_integer(),
          max_visible: pos_integer(),
          empty_label: String.t()
        }

  @spec new(
          [Entry.t() | Item.t() | keyword() | map() | :separator | {:section, String.t()}],
          keyword()
        ) :: t()
  def new(entries, opts \\ []) when is_list(entries) do
    entries = Enum.map(entries, &Entry.new/1)

    %__MODULE__{
      entries: entries,
      selected: Keyword.get(opts, :selected, first_selectable_index(entries)),
      max_visible: Keyword.get(opts, :max_visible, 8),
      empty_label: Keyword.get(opts, :empty_label, "No menu items")
    }
    |> clamp_selected()
  end

  @spec selected_item(t()) :: Item.t() | nil
  def selected_item(%__MODULE__{} = state) do
    case Enum.at(state.entries, state.selected) do
      %Entry{kind: :item, item: %Item{disabled?: false} = item} -> item
      _ -> nil
    end
  end

  @spec move(t(), integer()) :: t()
  def move(%__MODULE__{} = state, delta) when is_integer(delta) do
    indexes = selectable_indexes(state.entries)

    case indexes do
      [] -> %{state | selected: 0}
      _ -> %{state | selected: next_index(indexes, state.selected, delta)}
    end
  end

  @spec clamp_selected(t()) :: t()
  def clamp_selected(%__MODULE__{} = state) do
    indexes = selectable_indexes(state.entries)

    cond do
      indexes == [] ->
        %{state | selected: 0}

      state.selected in indexes ->
        state

      true ->
        %{state | selected: first_after(indexes, state.selected)}
    end
  end

  @spec selectable_indexes([Entry.t()]) :: [non_neg_integer()]
  def selectable_indexes(entries) do
    entries
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {%Entry{kind: :item, item: %Item{disabled?: false}}, index} -> [index]
      _entry -> []
    end)
  end

  defp first_selectable_index(entries), do: entries |> selectable_indexes() |> List.first(0)

  defp next_index(indexes, selected, delta) do
    current_position = Enum.find_index(indexes, &(&1 == selected)) || 0
    position = (current_position + delta) |> max(0) |> min(length(indexes) - 1)
    Enum.at(indexes, position)
  end

  defp first_after(indexes, selected) do
    Enum.find(indexes, List.first(indexes), &(&1 >= selected))
  end
end
