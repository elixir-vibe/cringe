defmodule Cringe.Widgets.Tabs.State do
  @moduledoc """
  Explicit selection state for `Cringe.Widgets.Tabs`.
  """

  alias Cringe.Widgets.Tabs.Tab

  @enforce_keys [:tabs]
  defstruct tabs: [], selected: 0

  @type t :: %__MODULE__{tabs: [Tab.t()], selected: non_neg_integer()}

  @spec new([Tab.t() | keyword() | map()], keyword()) :: t()
  def new(tabs, opts \\ []) when is_list(tabs) do
    tabs = Enum.map(tabs, &normalize_tab/1)
    %__MODULE__{tabs: tabs, selected: Keyword.get(opts, :selected, 0)} |> clamp_selected()
  end

  @spec selected_tab(t()) :: Tab.t() | nil
  def selected_tab(%__MODULE__{} = state), do: Enum.at(state.tabs, state.selected)

  @spec move(t(), integer()) :: t()
  def move(%__MODULE__{} = state, delta) when is_integer(delta) do
    case length(state.tabs) do
      0 -> %{state | selected: 0}
      count -> %{state | selected: (state.selected + delta) |> max(0) |> min(count - 1)}
    end
  end

  @spec select(t(), term()) :: t()
  def select(%__MODULE__{} = state, id) do
    case Enum.find_index(state.tabs, &(&1.id == id)) do
      nil -> state
      index -> %{state | selected: index}
    end
  end

  @spec clamp_selected(t()) :: t()
  def clamp_selected(%__MODULE__{} = state) do
    case length(state.tabs) do
      0 -> %{state | selected: 0}
      count -> %{state | selected: state.selected |> max(0) |> min(count - 1)}
    end
  end

  defp normalize_tab(%Tab{} = tab), do: tab
  defp normalize_tab(attrs), do: Tab.new(attrs)
end
