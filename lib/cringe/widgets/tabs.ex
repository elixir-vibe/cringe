defmodule Cringe.Widgets.Tabs do
  @moduledoc """
  Generic tabs widget with explicit selection state.

  Tabs render a tab bar and the selected tab content. Content may be a terminal
  document or a value converted to text.

      alias Cringe.Widgets.Tabs
      alias Cringe.Widgets.Tabs.State

      state = State.new([%{id: :overview, label: "Overview", content: "Ready"}])
      {:select, _tab, ^state} = Tabs.update(state, Cringe.Event.key(:enter))

  `update/3` accepts a custom `Cringe.Keymap`.
  """

  alias Cringe.Document.Stack
  alias Cringe.Keymap
  alias Cringe.Measure
  alias Cringe.Widgets.Tabs.State
  alias Cringe.Widgets.Tabs.Tab

  @type update_result :: {:ok, State.t()} | {:select, Tab.t(), State.t()} | :ignored

  @spec new(keyword()) :: Cringe.Document.t()
  def new(opts \\ []) do
    state = state_from_opts(opts)
    width = Keyword.get(opts, :width, 80)

    [tab_bar(state, width), selected_content(state)]
    |> Enum.reject(&is_nil/1)
    |> Stack.new(:vertical, container_opts(opts))
  end

  @spec render(State.t(), keyword()) :: Cringe.Document.t()
  def render(%State{} = state, opts \\ []), do: new(Keyword.put(opts, :state, state))

  @spec default_keymap() :: Keymap.t()
  def default_keymap do
    Keymap.new(next: [:right, :tab, :l], previous: [:left, :h], select: [:enter])
  end

  @spec update(State.t(), Cringe.Event.t()) :: update_result()
  def update(%State{} = state, event), do: update(state, event, default_keymap())

  @spec update(State.t(), Cringe.Event.t(), Keymap.t()) :: update_result()
  def update(%State{} = state, event, %Keymap{} = keymap) do
    case Keymap.action(keymap, event) do
      {:ok, :next} -> {:ok, State.move(state, 1)}
      {:ok, :previous} -> {:ok, State.move(state, -1)}
      {:ok, :select} -> select_tab(state)
      _ -> :ignored
    end
  end

  defp state_from_opts(opts) do
    case Keyword.get(opts, :state) do
      %State{} = state -> state
      nil -> State.new(Keyword.get(opts, :tabs, []), selected: Keyword.get(opts, :selected, 0))
    end
  end

  defp container_opts(opts) do
    opts
    |> Keyword.drop([:tabs, :state, :selected, :width, :selected_style, :tab_style])
    |> Keyword.put_new(:role, :tabs)
  end

  defp tab_bar(%State{} = state, width) do
    state.tabs
    |> Enum.with_index()
    |> Enum.map_join(" ", fn {%Tab{} = tab, index} -> tab_label(tab, index == state.selected) end)
    |> Measure.take(width)
    |> Cringe.text(role: :tab_bar)
  end

  defp tab_label(%Tab{} = tab, true), do: "[ #{tab.label} ]"
  defp tab_label(%Tab{} = tab, false), do: "  #{tab.label}  "

  defp selected_content(%State{} = state) do
    case State.selected_tab(state) do
      nil -> nil
      %Tab{content: nil} -> nil
      %Tab{content: content} -> content_document(content)
    end
  end

  defp content_document(%_{} = document), do: document
  defp content_document(content), do: Cringe.text(to_string(content), role: :tab_panel)

  defp select_tab(%State{} = state) do
    case State.selected_tab(state) do
      nil -> :ignored
      %Tab{} = tab -> {:select, tab, state}
    end
  end
end
