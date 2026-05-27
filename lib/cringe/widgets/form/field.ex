defmodule Cringe.Widgets.Form.Field do
  @moduledoc """
  Field definition and state for `Cringe.Widgets.Form`.
  """

  alias Cringe.Widgets.Editor
  alias Cringe.Widgets.Input

  @enforce_keys [:id, :control, :state]
  defstruct [:id, :control, :state, label: nil, opts: []]

  @type control :: :input | :editor | :select
  @type t :: %__MODULE__{
          id: term(),
          control: control(),
          state: term(),
          label: String.t() | nil,
          opts: keyword()
        }

  @spec input(term(), keyword()) :: t()
  def input(id, opts \\ []) do
    value = Keyword.get(opts, :value, "")
    state = Keyword.get(opts, :state, Input.State.new(value))
    new(id, :input, state, opts)
  end

  @spec editor(term(), keyword()) :: t()
  def editor(id, opts \\ []) do
    value = Keyword.get(opts, :value, "")
    state = Keyword.get(opts, :state, Editor.State.new(value))
    new(id, :editor, state, opts)
  end

  @spec select(term(), [term()], keyword()) :: t()
  def select(id, options, opts \\ []) when is_list(options) do
    state = Keyword.get(opts, :selected, 0)

    id
    |> new(:select, state, opts)
    |> put_opt(:options, options)
  end

  @spec new(term(), control(), term(), keyword()) :: t()
  def new(id, control, state, opts \\ []) when control in [:input, :editor, :select] do
    %__MODULE__{
      id: id,
      control: control,
      state: state,
      label: label(id, opts),
      opts: Keyword.drop(opts, [:state, :value, :selected, :label])
    }
  end

  @spec put_state(t(), term()) :: t()
  def put_state(%__MODULE__{} = field, state), do: %{field | state: state}

  defp put_opt(%__MODULE__{} = field, key, value),
    do: %{field | opts: Keyword.put(field.opts, key, value)}

  defp label(id, opts) do
    case Keyword.get(opts, :label) do
      nil -> id |> to_string() |> String.capitalize()
      false -> nil
      label -> to_string(label)
    end
  end
end
