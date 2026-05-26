defmodule Cringe.Event.Text do
  @moduledoc """
  Text input event.
  """

  @enforce_keys [:text]
  defstruct [:text]

  @type t :: %__MODULE__{text: String.t()}

  @spec new(String.t()) :: t()
  def new(text) when is_binary(text), do: %__MODULE__{text: text}
end
