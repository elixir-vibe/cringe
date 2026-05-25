defmodule Cringe.Measure do
  @moduledoc false

  @spec width(String.t()) :: non_neg_integer()
  def width(text) when is_binary(text), do: String.length(text)

  @spec take(String.t(), non_neg_integer()) :: String.t()
  def take(text, width) when is_binary(text) and is_integer(width) and width >= 0 do
    text
    |> String.graphemes()
    |> Enum.take(width)
    |> Enum.join()
  end

  @spec pad(String.t(), non_neg_integer()) :: String.t()
  def pad(text, width) when is_binary(text) and is_integer(width) do
    text <> String.duplicate(" ", max(width - width(text), 0))
  end
end
