defmodule Cringe.Rect do
  @moduledoc """
  Rectangle used by layout and painting code.
  """

  @enforce_keys [:x, :y, :width, :height]
  defstruct [:x, :y, :width, :height]

  @type t :: %__MODULE__{
          x: non_neg_integer(),
          y: non_neg_integer(),
          width: non_neg_integer(),
          height: non_neg_integer()
        }

  @spec new(non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer()) :: t()
  def new(x, y, width, height), do: %__MODULE__{x: x, y: y, width: width, height: height}
end
