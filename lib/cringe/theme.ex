defmodule Cringe.Theme do
  @moduledoc """
  Default widget theme tokens.
  """

  @spec input(keyword()) :: keyword()
  def input(opts \\ []), do: Cringe.Style.merge([placeholder_color: :bright_black], opts)

  @spec select(keyword()) :: keyword()
  def select(opts \\ []), do: Cringe.Style.merge([marker: "›"], opts)

  @spec progress(keyword()) :: keyword()
  def progress(opts \\ []), do: Cringe.Style.merge([width: 20], opts)
end
