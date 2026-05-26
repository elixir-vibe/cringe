defmodule Cringe.Event.Tick do
  @moduledoc """
  Timer tick event.
  """

  @enforce_keys [:id]
  defstruct [:id]

  @type t :: %__MODULE__{id: term()}

  @spec new(term()) :: t()
  def new(id), do: %__MODULE__{id: id}
end
