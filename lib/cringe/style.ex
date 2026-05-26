defmodule Cringe.Style do
  @moduledoc """
  Small style normalization helpers shared by widgets.
  """

  @type t :: keyword()

  @spec merge(keyword(), keyword()) :: keyword()
  def merge(defaults, opts), do: Keyword.merge(defaults, opts)

  @spec variant(atom(), keyword()) :: keyword()
  def variant(:focused, opts), do: merge([bold: true, color: :cyan], opts)
  def variant(:selected, opts), do: merge([color: :green], opts)
  def variant(:disabled, opts), do: merge([color: :bright_black], opts)
  def variant(:muted, opts), do: merge([color: :bright_black], opts)
  def variant(_variant, opts), do: opts
end
