defmodule Cringe.Widgets.Dialog do
  @moduledoc """
  Generic dialog widget with title, body, and selectable actions.

  Dialogs render content and report selected or cancelled actions. Apps decide
  whether a dialog is inline, modal, or rendered through an overlay layer.

      alias Cringe.Widgets.Dialog
      alias Cringe.Widgets.Dialog.State

      state = State.new([%{id: :cancel, label: "Cancel"}, %{id: :ok, label: "OK"}])
      {:ok, state} = Dialog.update(state, Cringe.Event.key(:right))

  `update/3` accepts a custom `Cringe.Keymap`.
  """

  alias Cringe.Document.{Box, Stack}
  alias Cringe.Keymap
  alias Cringe.Measure
  alias Cringe.Widgets.Dialog.Action
  alias Cringe.Widgets.Dialog.State

  @type update_result ::
          {:ok, State.t()} | {:select, Action.t(), State.t()} | {:cancel, State.t()} | :ignored

  @spec new(keyword()) :: Cringe.Document.t()
  def new(opts \\ []) do
    state = state_from_opts(opts)
    title = Keyword.get(opts, :title)
    body = Keyword.get(opts, :body, [])
    width = Keyword.get(opts, :width, 48)

    [title_line(title), body_lines(body, width), action_row(state)]
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Stack.new(:vertical, gap: 1, role: :dialog_content)
    |> Box.new(box_opts(opts))
  end

  @spec render(State.t(), keyword()) :: Cringe.Document.t()
  def render(%State{} = state, opts \\ []), do: new(Keyword.put(opts, :state, state))

  @spec default_keymap() :: Keymap.t()
  def default_keymap do
    Keymap.new(
      next: [:right, :down, :tab, :l],
      previous: [:left, :up, :h],
      select: [:enter, :space],
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
      {:ok, :select} -> select_action(state)
      {:ok, :cancel} -> {:cancel, state}
      _ -> :ignored
    end
  end

  defp state_from_opts(opts) do
    case Keyword.get(opts, :state) do
      %State{} = state -> state
      nil -> State.new(Keyword.get(opts, :actions, []), selected: Keyword.get(opts, :selected, 0))
    end
  end

  defp box_opts(opts) do
    opts
    |> Keyword.drop([
      :state,
      :actions,
      :selected,
      :title,
      :body,
      :width,
      :selected_style,
      :action_style
    ])
    |> Keyword.put_new(:padding, 1)
    |> Keyword.put_new(:role, :dialog)
  end

  defp title_line(nil), do: nil
  defp title_line(title), do: Cringe.text(to_string(title), bold: true, role: :dialog_title)

  defp body_lines(body, width) when is_binary(body) do
    body
    |> Measure.wrap(max(width, 1))
    |> Enum.map(&Cringe.text(&1, role: :dialog_body))
  end

  defp body_lines(body, _width) when is_list(body), do: Enum.map(body, &body_line/1)
  defp body_lines(body, width), do: body |> to_string() |> body_lines(width)

  defp body_line(%_{} = document), do: document
  defp body_line(text), do: Cringe.text(to_string(text), role: :dialog_body)

  defp action_row(%State{actions: []}), do: nil

  defp action_row(%State{} = state) do
    state.actions
    |> Enum.with_index()
    |> Enum.map(fn {%Action{} = action, index} ->
      action_text(action, index == state.selected)
    end)
    |> Stack.new(:horizontal, gap: 1, role: :dialog_actions)
  end

  defp action_text(%Action{} = action, true) do
    Cringe.text("[ #{action.label} ]", Cringe.Style.variant(:focused, role: :dialog_action))
  end

  defp action_text(%Action{} = action, false),
    do: Cringe.text("  #{action.label}  ", role: :dialog_action)

  defp select_action(%State{} = state) do
    case State.selected_action(state) do
      nil -> :ignored
      %Action{} = action -> {:select, action, state}
    end
  end
end
