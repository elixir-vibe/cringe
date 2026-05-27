defmodule Cringe.Widgets.Table.Column do
  @moduledoc """
  Column definition for `Cringe.Widgets.Table`.
  """

  @enforce_keys [:id, :label]
  defstruct [:id, :label, width: nil, align: :left]

  @type align :: :left | :right
  @type t :: %__MODULE__{
          id: term(),
          label: String.t(),
          width: pos_integer() | nil,
          align: align()
        }

  @spec new(keyword() | map()) :: t()
  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)
    id = Map.fetch!(attrs, :id)

    %__MODULE__{
      id: id,
      label: attrs |> Map.get(:label, id) |> to_string(),
      width: Map.get(attrs, :width),
      align: Map.get(attrs, :align, :left)
    }
  end
end
