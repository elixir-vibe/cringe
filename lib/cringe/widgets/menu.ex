defmodule Cringe.Widgets.Menu do
  @moduledoc """
  Generic action menu with sections, separators, shortcuts, and disabled items.

  Menus report selected items but do not impose command-palette, autocomplete, or
  application command semantics.

      alias Cringe.Widgets.Menu
      alias Cringe.Widgets.Menu.State

      state = State.new([%{id: :open, label: "Open", shortcut: "Enter"}])
      {:select, _item, ^state} = Menu.update(state, Cringe.Event.key(:enter))

  `update/3` accepts a custom `Cringe.Keymap`.
  """

  alias Cringe.Document.Stack
  alias Cringe.Keymap
  alias Cringe.Measure
  alias Cringe.Widgets.Menu.Entry
  alias Cringe.Widgets.Menu.Item
  alias Cringe.Widgets.Menu.State

  @marker "› "
  @blank "  "
  @primary_gap 2
  @min_description_width 10

  @type update_result ::
          {:ok, State.t()} | {:select, Item.t(), State.t()} | {:cancel, State.t()} | :ignored

  @spec new(keyword()) :: Cringe.Document.t()
  def new(opts \\ []) do
    state = state_from_opts(opts)
    width = Keyword.get(opts, :width, 80)

    opts
    |> Keyword.drop([
      :entries,
      :items,
      :state,
      :selected,
      :max_visible,
      :empty_label,
      :width,
      :style,
      :selected_style,
      :disabled_style,
      :section_style,
      :separator_style,
      :scroll_style,
      :empty_style
    ])
    |> Keyword.put_new(:role, :menu)
    |> then(&Stack.new(lines(state, width, opts), :vertical, &1))
  end

  @spec render(State.t(), keyword()) :: Cringe.Document.t()
  def render(%State{} = state, opts \\ []), do: new(Keyword.put(opts, :state, state))

  @spec default_keymap() :: Keymap.t()
  def default_keymap do
    Keymap.new(
      next: [:down, :j],
      previous: [:up, :k],
      select: [:enter],
      cancel: [:escape, {:c, [:ctrl]}]
    )
  end

  @spec update(State.t(), Cringe.Event.t()) :: update_result()
  def update(%State{} = state, event), do: update(state, event, default_keymap())

  @spec update(State.t(), Cringe.Event.t(), Keymap.t()) :: update_result()
  def update(%State{} = state, event, %Keymap{} = keymap) do
    keymap
    |> Keymap.action(event)
    |> apply_action(state)
  end

  defp apply_action({:ok, :next}, state), do: {:ok, State.move(state, 1)}
  defp apply_action({:ok, :previous}, state), do: {:ok, State.move(state, -1)}
  defp apply_action({:ok, :select}, state), do: select_item(state)
  defp apply_action({:ok, :cancel}, state), do: {:cancel, state}
  defp apply_action(_action, _state), do: :ignored

  @spec lines(State.t(), pos_integer(), keyword()) :: [Cringe.Document.t()]
  def lines(%State{} = state, width, opts \\ []) when is_integer(width) and width > 0 do
    if State.selectable_indexes(state.entries) == [] do
      [Cringe.text("  " <> state.empty_label, Keyword.get(opts, :empty_style, []))]
    else
      {start_index, entries} = visible_entries(state)
      primary_width = primary_width(entries)

      entries
      |> Enum.with_index(start_index)
      |> Enum.map(fn {%Entry{} = entry, index} ->
        Cringe.text(
          row(entry, index == state.selected, width, primary_width),
          row_style(entry, index == state.selected, opts)
        )
      end)
      |> maybe_scroll_line(state, opts)
    end
  end

  defp state_from_opts(opts) do
    case Keyword.get(opts, :state) do
      %State{} = state ->
        state

      nil ->
        State.new(Keyword.get(opts, :entries, Keyword.get(opts, :items, [])),
          selected: Keyword.get(opts, :selected),
          max_visible: Keyword.get(opts, :max_visible, 8),
          empty_label: Keyword.get(opts, :empty_label, "No menu items")
        )
    end
  end

  defp visible_entries(%State{} = state) do
    max_visible = max(state.max_visible, 1)

    start_index =
      max(0, min(state.selected - div(max_visible, 2), length(state.entries) - max_visible))

    {start_index, Enum.slice(state.entries, start_index, max_visible)}
  end

  defp maybe_scroll_line(lines, %State{} = state, opts) do
    if length(state.entries) > state.max_visible do
      lines ++
        [
          Cringe.text(
            "  (#{state.selected + 1}/#{length(state.entries)})",
            Keyword.get(opts, :scroll_style, [])
          )
        ]
    else
      lines
    end
  end

  defp primary_width(entries) do
    entries
    |> Enum.reduce(0, fn
      %Entry{kind: :item, item: %Item{} = item}, width ->
        max(width, Measure.width(item.label) + @primary_gap)

      _entry, width ->
        width
    end)
    |> max(1)
  end

  defp row(%Entry{kind: :section, label: label}, _selected?, width, _primary_width) do
    Measure.take(to_string(label), width)
  end

  defp row(%Entry{kind: :separator}, _selected?, width, _primary_width) do
    Measure.take(String.duplicate("─", width), width)
  end

  defp row(%Entry{kind: :item, item: %Item{} = item}, selected?, width, primary_width) do
    prefix = if selected?, do: @marker, else: @blank
    label_width = max(1, min(primary_width, width - Measure.width(prefix)))
    label = Measure.fit(item.label, label_width)
    shortcut = if item.shortcut, do: " " <> item.shortcut, else: ""
    description = item.description || ""
    remaining = width - Measure.width(prefix <> label <> shortcut) - 2

    Measure.take(prefix <> label <> suffix(shortcut, description, remaining), width)
  end

  defp suffix(shortcut, description, remaining)
       when shortcut != "" and description != "" and remaining > @min_description_width do
    shortcut <> "  " <> Measure.take(description, remaining)
  end

  defp suffix(shortcut, _description, _remaining) when shortcut != "", do: shortcut

  defp suffix(_shortcut, description, remaining)
       when description != "" and remaining > @min_description_width do
    Measure.take(description, remaining)
  end

  defp suffix(_shortcut, _description, _remaining), do: ""

  defp row_style(%Entry{kind: :section}, _selected?, opts),
    do: Keyword.get(opts, :section_style, Cringe.Style.variant(:muted, []))

  defp row_style(%Entry{kind: :separator}, _selected?, opts),
    do: Keyword.get(opts, :separator_style, Cringe.Style.variant(:muted, []))

  defp row_style(%Entry{kind: :item, item: %Item{disabled?: true}}, _selected?, opts),
    do: Keyword.get(opts, :disabled_style, Cringe.Style.variant(:disabled, []))

  defp row_style(%Entry{kind: :item}, true, opts),
    do: Keyword.get(opts, :selected_style, Cringe.Style.variant(:selected, []))

  defp row_style(%Entry{kind: :item}, false, opts), do: Keyword.get(opts, :style, [])

  defp select_item(%State{} = state) do
    case State.selected_item(state) do
      nil -> :ignored
      %Item{} = item -> {:select, item, state}
    end
  end
end
