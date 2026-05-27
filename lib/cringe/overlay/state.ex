defmodule Cringe.Overlay.State do
  @moduledoc """
  Ordered overlay layer state.
  """

  alias Cringe.Overlay.Layer

  defstruct layers: []

  @type t :: %__MODULE__{layers: [Layer.t()]}

  @spec new([Layer.t()]) :: t()
  def new(layers \\ []) when is_list(layers), do: %__MODULE__{layers: layers}

  @spec put(t(), Layer.t()) :: t()
  def put(%__MODULE__{} = state, %Layer{} = layer) do
    %{state | layers: state.layers |> Enum.reject(&(&1.id == layer.id)) |> Kernel.++([layer])}
  end

  @spec remove(t(), term()) :: t()
  def remove(%__MODULE__{} = state, id) do
    %{state | layers: Enum.reject(state.layers, &(&1.id == id))}
  end

  @spec top(t()) :: Layer.t() | nil
  def top(%__MODULE__{layers: []}), do: nil
  def top(%__MODULE__{layers: layers}), do: List.last(layers)

  @spec capturing(t()) :: Layer.t() | nil
  def capturing(%__MODULE__{} = state) do
    state.layers
    |> Enum.reverse()
    |> Enum.find(& &1.capture?)
  end
end
