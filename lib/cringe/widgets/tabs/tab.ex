defmodule Cringe.Widgets.Tabs.Tab do
  @moduledoc """
  Tab definition for `Cringe.Widgets.Tabs`.
  """

  @enforce_keys [:id, :label]
  defstruct [:id, :label, content: nil]

  @type t :: %__MODULE__{
          id: term(),
          label: String.t(),
          content: Cringe.Document.t() | String.t() | nil
        }

  @spec new(keyword() | map()) :: t()
  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)
    id = Map.fetch!(attrs, :id)

    %__MODULE__{
      id: id,
      label: attrs |> Map.get(:label, id) |> to_string(),
      content: Map.get(attrs, :content)
    }
  end
end
