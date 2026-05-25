defmodule Cringe.Document.Box do
  @moduledoc """
  Box container node for terminal documents.
  """

  @enforce_keys [:child]
  defstruct [:child, opts: []]

  @type t :: %__MODULE__{child: Cringe.Document.t(), opts: keyword()}

  @spec new(Cringe.Document.t(), keyword()) :: t()
  def new(child, opts \\ []) when is_list(opts) do
    %__MODULE__{child: child, opts: opts}
  end
end
