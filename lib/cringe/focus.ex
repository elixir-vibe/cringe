defmodule Cringe.Focus do
  @moduledoc """
  Deterministic focus ring helpers.
  """

  @enforce_keys [:ids]
  defstruct [:ids, index: 0]

  @type t :: %__MODULE__{ids: [term()], index: non_neg_integer()}

  @spec new([term()], keyword()) :: t()
  def new(ids, opts \\ []) when is_list(ids) do
    index = opts |> Keyword.get(:current, List.first(ids)) |> index_for(ids)
    %__MODULE__{ids: ids, index: index}
  end

  @spec current(t()) :: term() | nil
  def current(%__MODULE__{ids: []}), do: nil
  def current(%__MODULE__{ids: ids, index: index}), do: Enum.at(ids, index)

  @spec focused?(t(), term()) :: boolean()
  def focused?(focus, id), do: current(focus) == id

  @spec next(t()) :: t()
  def next(%__MODULE__{ids: []} = focus), do: focus

  def next(%__MODULE__{ids: ids, index: index} = focus),
    do: %{focus | index: rem(index + 1, length(ids))}

  @spec previous(t()) :: t()
  def previous(%__MODULE__{ids: []} = focus), do: focus

  def previous(%__MODULE__{ids: ids, index: index} = focus) do
    %{focus | index: rem(index - 1 + length(ids), length(ids))}
  end

  defp index_for(nil, _ids), do: 0

  defp index_for(current, ids) do
    case Enum.find_index(ids, &(&1 == current)) do
      nil -> 0
      index -> index
    end
  end
end
