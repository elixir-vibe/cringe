defmodule Cringe.Document.Stack do
  @moduledoc """
  Ordered container node for terminal documents.
  """

  @enforce_keys [:children, :direction]
  defstruct [:children, :direction, opts: []]

  @type direction :: :vertical | :horizontal
  @type t :: %__MODULE__{children: [Cringe.Document.t()], direction: direction(), opts: keyword()}

  @spec new([Cringe.Document.t()], direction(), keyword()) :: t()
  def new(children, direction, opts \\ [])
      when direction in [:vertical, :horizontal] and is_list(opts) do
    %__MODULE__{children: List.wrap(children), direction: direction, opts: opts}
  end
end
