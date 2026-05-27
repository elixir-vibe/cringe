defmodule Cringe.Keymap.Binding do
  @moduledoc """
  A single keyboard binding.
  """

  alias Cringe.Event.Key

  @enforce_keys [:key]
  defstruct [:key, mods: []]

  @type t :: %__MODULE__{key: atom(), mods: [Key.mod()]}

  @spec new(atom(), keyword()) :: t()
  def new(key, opts \\ []) when is_atom(key) do
    %__MODULE__{key: key, mods: opts |> Keyword.get(:mods, []) |> normalize_mods()}
  end

  @spec matches?(t(), Cringe.Event.t()) :: boolean()
  def matches?(%__MODULE__{} = binding, %Key{} = event) do
    binding.key == event.key and normalize_mods(binding.mods) == normalize_mods(event.mods)
  end

  def matches?(%__MODULE__{}, _event), do: false

  @doc false
  @spec normalize(t() | atom() | {atom(), [Key.mod()]}) :: t()
  def normalize(%__MODULE__{} = binding), do: binding
  def normalize(key) when is_atom(key), do: new(key)
  def normalize({key, mods}) when is_atom(key) and is_list(mods), do: new(key, mods: mods)

  defp normalize_mods(mods), do: mods |> Enum.uniq() |> Enum.sort()
end
