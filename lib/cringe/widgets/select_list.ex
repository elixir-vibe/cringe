defmodule Cringe.Widgets.SelectList do
  @moduledoc """
  Scrollable select-list widget with aligned descriptions.

  `SelectList` keeps its interaction state explicit and renderable. Use the
  structs in `Cringe.Widgets.SelectList.State` and
  `Cringe.Widgets.SelectList.Item` when storing widget state in an app.

      alias Cringe.Widgets.SelectList
      alias Cringe.Widgets.SelectList.State

      state = State.new([%{id: :one, label: "One"}, %{id: :two, label: "Two"}])
      {:ok, state} = SelectList.update(state, Cringe.Event.key(:down))

  `update/3` accepts a custom `Cringe.Keymap`.
  """

  alias Cringe.Document.Stack
  alias Cringe.Keymap
  alias Cringe.Measure
  alias Cringe.Widgets.SelectList.Item
  alias Cringe.Widgets.SelectList.State

  @primary_gap 2
  @min_description_width 10

  @type update_result ::
          {:ok, State.t()}
          | {:select, Item.t(), State.t()}
          | {:cancel, State.t()}
          | :ignored

  @spec new(keyword()) :: Cringe.Document.t()
  def new(opts \\ []) do
    state = state_from_opts(opts)

    opts
    |> Keyword.drop([
      :state,
      :items,
      :selected,
      :max_visible,
      :filter,
      :empty_label,
      :marker,
      :min_primary_width,
      :max_primary_width,
      :width,
      :style,
      :selected_style,
      :scroll_style,
      :empty_style
    ])
    |> Keyword.put_new(:role, :select_list)
    |> Keyword.put_new(:focusable, true)
    |> then(&Stack.new(lines(state, Keyword.get(opts, :width, 80), opts), :vertical, &1))
  end

  @spec render(State.t(), keyword()) :: Cringe.Document.t()
  def render(%State{} = state, opts \\ []), do: new(Keyword.put(opts, :state, state))

  @spec default_keymap() :: Keymap.t()
  def default_keymap do
    Keymap.new(
      next: [:down, :right, :j],
      previous: [:up, :left, :k],
      select: [:enter],
      cancel: [:escape, {:c, [:ctrl]}]
    )
  end

  @spec update(State.t(), Cringe.Event.t()) :: update_result()
  def update(%State{} = state, event), do: update(state, event, default_keymap())

  @spec update(State.t(), Cringe.Event.t(), Keymap.t()) :: update_result()
  def update(%State{} = state, event, %Keymap{} = keymap) do
    case Keymap.action(keymap, event) do
      {:ok, :next} -> {:ok, State.move(state, 1)}
      {:ok, :previous} -> {:ok, State.move(state, -1)}
      {:ok, :select} -> select_item(state)
      {:ok, :cancel} -> {:cancel, state}
      _ -> :ignored
    end
  end

  @spec lines(State.t(), pos_integer(), keyword()) :: [Cringe.Document.t()]
  def lines(%State{} = state, width, opts \\ []) when is_integer(width) and width > 0 do
    items = State.filtered_items(state)

    if items == [] do
      [Cringe.text("  " <> state.empty_label, Keyword.get(opts, :empty_style, []))]
    else
      primary_width = primary_width(items, state)
      {start_index, visible_items} = visible_items(items, state)

      visible_items
      |> Enum.with_index(start_index)
      |> Enum.map(fn {%Item{} = item, index} ->
        selected? = index == state.selected
        Cringe.text(row(item, selected?, width, primary_width, state), row_style(selected?, opts))
      end)
      |> maybe_scroll_line(items, state, opts)
    end
  end

  defp select_item(%State{} = state) do
    case State.selected_item(state) do
      nil -> :ignored
      %Item{} = item -> {:select, item, state}
    end
  end

  defp state_from_opts(opts) do
    case Keyword.get(opts, :state) do
      %State{} = state -> state
      nil -> State.new(Keyword.get(opts, :items, []), opts)
    end
  end

  defp visible_items(items, %State{} = state) do
    max_visible = max(state.max_visible, 1)

    start_index =
      0
      |> max(min(state.selected - div(max_visible, 2), length(items) - max_visible))

    {start_index, Enum.slice(items, start_index, max_visible)}
  end

  defp maybe_scroll_line(lines, items, %State{} = state, opts) do
    if length(items) > state.max_visible do
      scroll_style = Keyword.get(opts, :scroll_style, [])
      lines ++ [Cringe.text("  (#{state.selected + 1}/#{length(items)})", scroll_style)]
    else
      lines
    end
  end

  defp primary_width(items, %State{} = state) do
    widest =
      Enum.reduce(items, 0, fn %Item{} = item, width ->
        max(width, Measure.width(item.label) + @primary_gap)
      end)

    widest
    |> max(state.min_primary_width)
    |> min(max(state.min_primary_width, state.max_primary_width))
  end

  defp row(%Item{} = item, selected?, width, primary_width, %State{} = state) do
    prefix =
      if selected?,
        do: state.marker <> " ",
        else: String.duplicate(" ", Measure.width(state.marker)) <> " "

    prefix_width = Measure.width(prefix)
    label_width = max(1, min(primary_width, width - prefix_width - 1))
    label = Measure.fit(item.label, label_width)

    case item.description do
      description when is_binary(description) and width > 40 ->
        used = prefix_width + label_width
        remaining = width - used - 2

        if remaining > @min_description_width do
          prefix <> label <> Measure.take(description, remaining)
        else
          Measure.take(prefix <> String.trim_trailing(label), width)
        end

      _ ->
        Measure.take(prefix <> String.trim_trailing(label), width)
    end
  end

  defp row_style(true, opts),
    do: Keyword.get(opts, :selected_style, Cringe.Style.variant(:selected, []))

  defp row_style(false, opts), do: Keyword.get(opts, :style, [])
end
