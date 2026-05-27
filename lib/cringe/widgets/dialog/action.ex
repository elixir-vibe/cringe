defmodule Cringe.Widgets.Dialog.Action do
  @moduledoc """
  Action displayed by `Cringe.Widgets.Dialog`.
  """

  @enforce_keys [:id, :label]
  defstruct [:id, :label, value: nil]

  @type t :: %__MODULE__{id: term(), label: String.t(), value: term()}

  @spec new(keyword() | map()) :: t()
  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)
    id = Map.fetch!(attrs, :id)

    %__MODULE__{
      id: id,
      label: attrs |> Map.get(:label, id) |> to_string(),
      value: Map.get(attrs, :value, id)
    }
  end
end
