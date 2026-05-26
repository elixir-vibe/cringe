defmodule Cringe.Event.Resize do
  @moduledoc """
  Terminal resize event.
  """

  @enforce_keys [:width, :height]
  defstruct [:width, :height]

  @type t :: %__MODULE__{width: pos_integer(), height: pos_integer()}

  @spec new(pos_integer(), pos_integer()) :: t()
  def new(width, height), do: %__MODULE__{width: width, height: height}
end
