defmodule Cringe.Widgets.SelectList.Item do
  @moduledoc """
  Item displayed by `Cringe.Widgets.SelectList`.
  """

  @enforce_keys [:id, :label]
  defstruct [:id, :label, :description, :value]

  @type t :: %__MODULE__{
          id: term(),
          label: String.t(),
          description: String.t() | nil,
          value: term()
        }

  @spec new(keyword() | map()) :: t()
  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)
    id = Map.fetch!(attrs, :id)
    label = attrs |> Map.fetch!(:label) |> to_string()

    %__MODULE__{
      id: id,
      label: label,
      description: description(attrs),
      value: Map.get(attrs, :value, id)
    }
  end

  defp description(attrs) do
    case Map.get(attrs, :description) do
      nil ->
        nil

      description ->
        description |> to_string() |> String.replace(~r/[\r\n]+/, " ") |> String.trim()
    end
  end
end
