defmodule Cringe.Widgets.Menu.Item do
  @moduledoc """
  Selectable menu item.
  """

  @enforce_keys [:id, :label]
  defstruct [:id, :label, :description, :shortcut, value: nil, disabled?: false]

  @type t :: %__MODULE__{
          id: term(),
          label: String.t(),
          description: String.t() | nil,
          shortcut: String.t() | nil,
          value: term(),
          disabled?: boolean()
        }

  @spec new(keyword() | map()) :: t()
  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)
    id = Map.fetch!(attrs, :id)

    %__MODULE__{
      id: id,
      label: attrs |> Map.get(:label, id) |> to_string(),
      description: text(attrs, :description),
      shortcut: text(attrs, :shortcut),
      value: Map.get(attrs, :value, id),
      disabled?: Map.get(attrs, :disabled?, false)
    }
  end

  defp text(attrs, key) do
    case Map.get(attrs, key) do
      nil -> nil
      value -> value |> to_string() |> String.replace(~r/[\r\n]+/, " ") |> String.trim()
    end
  end
end
