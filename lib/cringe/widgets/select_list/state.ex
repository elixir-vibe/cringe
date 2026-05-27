defmodule Cringe.Widgets.SelectList.State do
  @moduledoc """
  State for `Cringe.Widgets.SelectList`.
  """

  alias Cringe.Widgets.SelectList.Item

  @enforce_keys [:items]
  defstruct items: [],
            selected: 0,
            max_visible: 5,
            filter: "",
            empty_label: "No matching items",
            marker: "›",
            min_primary_width: 12,
            max_primary_width: 32

  @type t :: %__MODULE__{
          items: [Item.t()],
          selected: non_neg_integer(),
          max_visible: pos_integer(),
          filter: String.t(),
          empty_label: String.t(),
          marker: String.t(),
          min_primary_width: pos_integer(),
          max_primary_width: pos_integer()
        }

  @spec new([Item.t() | keyword() | map()], keyword()) :: t()
  def new(items, opts \\ []) when is_list(items) do
    normalized_items = Enum.map(items, &normalize_item/1)

    %__MODULE__{
      items: normalized_items,
      selected: Keyword.get(opts, :selected, 0),
      max_visible: Keyword.get(opts, :max_visible, 5),
      filter: Keyword.get(opts, :filter, ""),
      empty_label: Keyword.get(opts, :empty_label, "No matching items"),
      marker: Keyword.get(opts, :marker, "›"),
      min_primary_width: Keyword.get(opts, :min_primary_width, 12),
      max_primary_width: Keyword.get(opts, :max_primary_width, 32)
    }
    |> clamp_selected()
  end

  @spec filtered_items(t()) :: [Item.t()]
  def filtered_items(%__MODULE__{filter: "", items: items}), do: items

  def filtered_items(%__MODULE__{} = state) do
    filter = String.downcase(state.filter)

    Enum.filter(state.items, fn %Item{} = item ->
      item.label |> String.downcase() |> String.contains?(filter)
    end)
  end

  @spec selected_item(t()) :: Item.t() | nil
  def selected_item(%__MODULE__{} = state), do: Enum.at(filtered_items(state), state.selected)

  @spec put_filter(t(), String.t()) :: t()
  def put_filter(%__MODULE__{} = state, filter) when is_binary(filter) do
    %{state | filter: filter, selected: 0} |> clamp_selected()
  end

  @spec move(t(), integer()) :: t()
  def move(%__MODULE__{} = state, delta) when is_integer(delta) do
    items = filtered_items(state)

    case length(items) do
      0 -> %{state | selected: 0}
      count -> %{state | selected: (state.selected + delta) |> max(0) |> min(count - 1)}
    end
  end

  @spec clamp_selected(t()) :: t()
  def clamp_selected(%__MODULE__{} = state) do
    case length(filtered_items(state)) do
      0 -> %{state | selected: 0}
      count -> %{state | selected: state.selected |> max(0) |> min(count - 1)}
    end
  end

  defp normalize_item(%Item{} = item), do: item
  defp normalize_item(attrs), do: Item.new(attrs)
end
