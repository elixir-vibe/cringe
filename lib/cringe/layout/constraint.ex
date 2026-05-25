defmodule Cringe.Layout.Constraint do
  @moduledoc """
  Layout constraints derived from render options.
  """

  @enforce_keys [:width, :height]
  defstruct [:width, :height]

  @type dimension :: pos_integer() | nil
  @type t :: %__MODULE__{width: dimension(), height: dimension()}

  @spec new(keyword()) :: t()
  def new(opts) do
    %__MODULE__{width: Keyword.get(opts, :width), height: Keyword.get(opts, :height)}
  end
end
