defmodule Cringe.Widgets.Menu.Entry do
  @moduledoc """
  Menu entry: either a selectable item or a section/separator.
  """

  alias Cringe.Widgets.Menu.Item

  @enforce_keys [:kind]
  defstruct [:kind, :label, :item]

  @type kind :: :item | :section | :separator
  @type t :: %__MODULE__{kind: kind(), label: String.t() | nil, item: Item.t() | nil}

  @spec item(Item.t() | keyword() | map()) :: t()
  def item(%Item{} = item), do: %__MODULE__{kind: :item, item: item}
  def item(attrs), do: item(Item.new(attrs))

  @spec section(String.t()) :: t()
  def section(label), do: %__MODULE__{kind: :section, label: to_string(label)}

  @spec separator() :: t()
  def separator, do: %__MODULE__{kind: :separator}

  @spec new(t() | Item.t() | keyword() | map() | :separator | {:section, String.t()}) :: t()
  def new(%__MODULE__{} = entry), do: entry
  def new(%Item{} = item), do: item(item)
  def new(:separator), do: separator()
  def new({:section, label}), do: section(label)

  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)

    case Map.get(attrs, :kind, :item) do
      :separator -> separator()
      :section -> section(Map.fetch!(attrs, :label))
      :item -> item(attrs)
    end
  end
end
