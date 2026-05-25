defmodule Cringe.Frame do
  @moduledoc """
  Rendered terminal frame.
  """

  @enforce_keys [:lines]
  defstruct [:lines, cursor: nil]

  @type t :: %__MODULE__{lines: [String.t()], cursor: {pos_integer(), pos_integer()} | nil}

  @spec new([String.t()], keyword()) :: t()
  def new(lines, opts \\ []) when is_list(lines) do
    %__MODULE__{lines: lines, cursor: Keyword.get(opts, :cursor)}
  end

  @spec text(t()) :: String.t()
  def text(%__MODULE__{lines: lines}), do: Enum.join(lines, "\n")
end
