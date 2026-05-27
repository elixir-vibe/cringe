defmodule Cringe.Widgets.Form do
  @moduledoc """
  Generic form container with explicit field state and focus navigation.

  Forms own focus and delegate events to field widgets. They do not impose
  submission, validation, or storage rules.

      alias Cringe.Widgets.Form
      alias Cringe.Widgets.Form.Field
      alias Cringe.Widgets.Form.State

      state = State.new([Field.input(:name), Field.select(:role, ["Admin", "Viewer"])])
      {:ok, state} = Form.update(state, Cringe.Event.key(:tab))
  """

  alias Cringe.Document.Stack
  alias Cringe.Event.Key
  alias Cringe.Widgets.Editor
  alias Cringe.Widgets.Form.Field
  alias Cringe.Widgets.Form.State
  alias Cringe.Widgets.Input
  alias Cringe.Widgets.Select

  @type update_result :: {:ok, State.t()} | :ignored

  @spec new(keyword()) :: Cringe.Document.t()
  def new(opts \\ []) do
    state = state_from_opts(opts)

    opts
    |> Keyword.drop([:state, :fields, :gap])
    |> Keyword.put_new(:role, :form)
    |> then(
      &Stack.new(lines(state), :vertical, Keyword.put_new(&1, :gap, Keyword.get(opts, :gap, 1)))
    )
  end

  @spec render(State.t(), keyword()) :: Cringe.Document.t()
  def render(%State{} = state, opts \\ []), do: new(Keyword.put(opts, :state, state))

  @spec update(State.t(), Cringe.Event.t()) :: update_result()
  def update(%State{} = state, %Key{key: :tab, mods: mods}) do
    direction = if :shift in mods, do: :previous, else: :next
    {:ok, State.move_focus(state, direction)}
  end

  def update(%State{} = state, event) do
    case State.current_field(state) do
      nil -> :ignored
      %Field{} = field -> update_field(state, field, event)
    end
  end

  @spec lines(State.t()) :: [Cringe.Document.t()]
  def lines(%State{} = state) do
    Enum.flat_map(state.fields, &field_lines(&1, State.focused?(state, &1.id)))
  end

  defp state_from_opts(opts) do
    case Keyword.get(opts, :state) do
      %State{} = state -> state
      nil -> State.new(Keyword.get(opts, :fields, []))
    end
  end

  defp field_lines(%Field{} = field, focused?) do
    control = render_field(field, focused?)

    case field.label do
      nil -> [control]
      label -> [Cringe.text(label, role: :form_label), control]
    end
  end

  defp render_field(%Field{control: :input} = field, focused?) do
    field.opts
    |> Keyword.put(:state, field.state)
    |> Keyword.put(:focused, focused?)
    |> Input.new()
  end

  defp render_field(%Field{control: :editor} = field, focused?) do
    field.opts
    |> Keyword.put(:state, field.state)
    |> Keyword.put(:focused, focused?)
    |> Editor.new()
  end

  defp render_field(%Field{control: :select} = field, focused?) do
    field.opts
    |> Keyword.put(:selected, field.state)
    |> Keyword.put(:focused, focused?)
    |> Select.new()
  end

  defp update_field(%State{} = state, %Field{control: :input} = field, event) do
    case Input.update(field.state, event) do
      {:ok, field_state} -> {:ok, State.put_field_state(state, field.id, field_state)}
      :ignored -> :ignored
    end
  end

  defp update_field(%State{} = state, %Field{control: :editor} = field, event) do
    case Editor.update(field.state, event) do
      {:ok, field_state} -> {:ok, State.put_field_state(state, field.id, field_state)}
      :ignored -> :ignored
    end
  end

  defp update_field(%State{} = state, %Field{control: :select} = field, event) do
    case Select.update(field.state, event, Keyword.fetch!(field.opts, :options)) do
      {:ok, field_state} -> {:ok, State.put_field_state(state, field.id, field_state)}
      :ignored -> :ignored
    end
  end
end
