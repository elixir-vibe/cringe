defmodule Cringe.Layout.Size do
  @moduledoc """
  Two-dimensional layout size.
  """

  @enforce_keys [:width, :height]
  defstruct [:width, :height]

  @type t :: %__MODULE__{width: non_neg_integer(), height: non_neg_integer()}

  @spec new(non_neg_integer(), non_neg_integer()) :: t()
  def new(width, height), do: %__MODULE__{width: width, height: height}
end
