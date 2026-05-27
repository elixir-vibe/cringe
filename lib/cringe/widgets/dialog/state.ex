defmodule Cringe.Widgets.Dialog.State do
  @moduledoc """
  Explicit state for `Cringe.Widgets.Dialog`.
  """

  alias Cringe.Widgets.Dialog.Action

  @enforce_keys [:actions]
  defstruct actions: [], selected: 0

  @type t :: %__MODULE__{actions: [Action.t()], selected: non_neg_integer()}

  @spec new([Action.t() | keyword() | map()], keyword()) :: t()
  def new(actions, opts \\ []) when is_list(actions) do
    actions = Enum.map(actions, &normalize_action/1)
    %__MODULE__{actions: actions, selected: Keyword.get(opts, :selected, 0)} |> clamp_selected()
  end

  @spec selected_action(t()) :: Action.t() | nil
  def selected_action(%__MODULE__{} = state), do: Enum.at(state.actions, state.selected)

  @spec move(t(), integer()) :: t()
  def move(%__MODULE__{} = state, delta) when is_integer(delta) do
    case length(state.actions) do
      0 -> %{state | selected: 0}
      count -> %{state | selected: (state.selected + delta) |> max(0) |> min(count - 1)}
    end
  end

  @spec clamp_selected(t()) :: t()
  def clamp_selected(%__MODULE__{} = state) do
    case length(state.actions) do
      0 -> %{state | selected: 0}
      count -> %{state | selected: state.selected |> max(0) |> min(count - 1)}
    end
  end

  defp normalize_action(%Action{} = action), do: action
  defp normalize_action(attrs), do: Action.new(attrs)
end
