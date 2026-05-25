defmodule Cringe.Document.Text do
  @moduledoc """
  Text node for terminal documents.
  """

  @enforce_keys [:content]
  defstruct [:content, opts: []]

  @type t :: %__MODULE__{content: String.t(), opts: keyword()}

  @spec new(IO.chardata(), keyword()) :: t()
  def new(content, opts \\ []) when is_list(opts) do
    %__MODULE__{content: IO.iodata_to_binary(content), opts: opts}
  end
end
