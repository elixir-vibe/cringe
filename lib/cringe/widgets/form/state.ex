defmodule Cringe.Widgets.Form.State do
  @moduledoc """
  Explicit state for `Cringe.Widgets.Form`.
  """

  alias Cringe.Focus
  alias Cringe.Widgets.Form.Field

  @enforce_keys [:fields, :focus]
  defstruct [:fields, :focus]

  @type t :: %__MODULE__{fields: [Field.t()], focus: Focus.t()}

  @spec new([Field.t()], keyword()) :: t()
  def new(fields, opts \\ []) when is_list(fields) do
    ids = Enum.map(fields, & &1.id)
    %__MODULE__{fields: fields, focus: Focus.new(ids, current: Keyword.get(opts, :current))}
  end

  @spec current_field(t()) :: Field.t() | nil
  def current_field(%__MODULE__{} = state), do: field(state, Focus.current(state.focus))

  @spec focused?(t(), term()) :: boolean()
  def focused?(%__MODULE__{} = state, id), do: Focus.focused?(state.focus, id)

  @spec field(t(), term()) :: Field.t() | nil
  def field(%__MODULE__{} = state, id), do: Enum.find(state.fields, &(&1.id == id))

  @spec field_state(t(), term()) :: term() | nil
  def field_state(%__MODULE__{} = state, id) do
    case field(state, id) do
      nil -> nil
      %Field{} = field -> field.state
    end
  end

  @spec put_field(t(), Field.t()) :: t()
  def put_field(%__MODULE__{} = state, %Field{} = field) do
    %{state | fields: Enum.map(state.fields, &replace_field(&1, field))}
  end

  @spec put_field_state(t(), term(), term()) :: t()
  def put_field_state(%__MODULE__{} = state, id, field_state) do
    case field(state, id) do
      nil -> state
      %Field{} = field -> put_field(state, Field.put_state(field, field_state))
    end
  end

  @spec move_focus(t(), :next | :previous) :: t()
  def move_focus(%__MODULE__{} = state, :next), do: %{state | focus: Focus.next(state.focus)}

  def move_focus(%__MODULE__{} = state, :previous),
    do: %{state | focus: Focus.previous(state.focus)}

  defp replace_field(%Field{id: id}, %Field{id: id} = next), do: next
  defp replace_field(field, _next), do: field
end
