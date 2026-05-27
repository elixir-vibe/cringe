defmodule Cringe.Widgets.Editor do
  @moduledoc """
  Render-only multiline editor widget and explicit editing helpers.

  The editor owns no prompt history, submission policy, or autocomplete
  semantics. Apps keep `Cringe.Widgets.Editor.State` and decide how to interpret
  events that the editor ignores.

      alias Cringe.Widgets.Editor
      alias Cringe.Widgets.Editor.State

      state = State.new("one\ntwo", cursor_line: 1, cursor_col: 3)
      {:ok, state} = Editor.update(state, Cringe.Event.key(:enter))

  `update/3` accepts a custom `Cringe.Keymap`.
  """

  alias Cringe.Document.Stack
  alias Cringe.Event.{Key, Text}
  alias Cringe.Keymap
  alias Cringe.Measure
  alias Cringe.Widgets.Editor.State
  alias Cringe.Widgets.Editor.Viewport

  @spec new(keyword()) :: Cringe.Document.t()
  def new(opts \\ []) do
    state = state_from_opts(opts)
    focused? = Keyword.get(opts, :focused, false)
    width = Keyword.get(opts, :width, 80)
    height = Keyword.get(opts, :height, length(state.lines))

    opts
    |> Keyword.drop([:state, :value, :cursor_line, :cursor_col, :focused, :width, :height])
    |> Keyword.put_new(:role, :editor)
    |> Keyword.put_new(:focusable, true)
    |> then(&Stack.new(lines(state, width, height, focused?), :vertical, &1))
  end

  @spec render(State.t(), keyword()) :: Cringe.Document.t()
  def render(%State{} = state, opts \\ []), do: new(Keyword.put(opts, :state, state))

  @spec default_keymap() :: Keymap.t()
  def default_keymap do
    Keymap.new(
      left: [:left],
      right: [:right],
      up: [:up],
      down: [:down],
      home: [:home],
      end: [:end],
      backspace: [:backspace],
      delete: [:delete],
      newline: [:enter]
    )
  end

  @spec update(State.t(), Cringe.Event.t()) :: {:ok, State.t()} | :ignored
  def update(%State{} = state, event), do: update(state, event, default_keymap())

  @spec update(State.t(), Cringe.Event.t(), Keymap.t()) :: {:ok, State.t()} | :ignored
  def update(%State{} = state, %Text{text: text}, %Keymap{}), do: {:ok, State.insert(state, text)}

  def update(%State{} = state, %Key{} = event, %Keymap{} = keymap) do
    keymap
    |> Keymap.action(event)
    |> apply_action(state)
  end

  def update(%State{}, _event, %Keymap{}), do: :ignored

  defp apply_action({:ok, :left}, state), do: {:ok, State.move(state, :left)}
  defp apply_action({:ok, :right}, state), do: {:ok, State.move(state, :right)}
  defp apply_action({:ok, :up}, state), do: {:ok, State.move(state, :up)}
  defp apply_action({:ok, :down}, state), do: {:ok, State.move(state, :down)}
  defp apply_action({:ok, :home}, state), do: {:ok, State.home(state)}
  defp apply_action({:ok, :end}, state), do: {:ok, State.end_of_line(state)}
  defp apply_action({:ok, :backspace}, state), do: {:ok, State.backspace(state)}
  defp apply_action({:ok, :delete}, state), do: {:ok, State.delete(state)}
  defp apply_action({:ok, :newline}, state), do: {:ok, State.insert(state, "\n")}
  defp apply_action(_action, _state), do: :ignored

  @spec lines(State.t(), pos_integer(), pos_integer(), boolean()) :: [Cringe.Document.t()]
  def lines(%State{} = state, width, height, focused?)
      when is_integer(width) and width > 0 and is_integer(height) and height > 0 do
    viewport = Viewport.new(state, width, height)

    state.lines
    |> Enum.slice(viewport.line, viewport.height)
    |> Enum.with_index(viewport.line)
    |> Enum.map(fn {line, index} ->
      Cringe.text(Measure.slice(line, viewport.column, viewport.width),
        cursor: cursor(state, viewport, index, focused?)
      )
    end)
  end

  @spec visible_start(State.t(), pos_integer()) :: non_neg_integer()
  def visible_start(%State{} = state, height), do: Viewport.line_start(state, height)

  @spec visible_column_start(State.t(), pos_integer()) :: non_neg_integer()
  def visible_column_start(%State{} = state, width), do: Viewport.column_start(state, width)

  defp state_from_opts(opts) do
    case Keyword.get(opts, :state) do
      %State{} = state ->
        state

      nil ->
        State.new(Keyword.get(opts, :value, ""),
          cursor_line: Keyword.get(opts, :cursor_line),
          cursor_col: Keyword.get(opts, :cursor_col)
        )
    end
  end

  defp cursor(_state, _viewport, _index, false), do: nil

  defp cursor(%State{cursor_line: cursor_line}, %Viewport{}, index, true)
       when cursor_line != index,
       do: nil

  defp cursor(%State{} = state, %Viewport{} = viewport, _index, true) do
    {1, Viewport.cursor_column(state, viewport)}
  end
end
