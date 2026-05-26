defmodule Cringe.Event.Key do
  @moduledoc """
  Keyboard event.
  """

  @enforce_keys [:key]
  defstruct [:key, mods: []]

  @type key :: atom()
  @type mod :: :alt | :ctrl | :meta | :shift
  @type t :: %__MODULE__{key: key(), mods: [mod()]}

  @spec new(key(), keyword()) :: t()
  def new(key, opts \\ []), do: %__MODULE__{key: key, mods: Keyword.get(opts, :mods, [])}
end
